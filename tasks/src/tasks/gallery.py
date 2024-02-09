import argparse
import hashlib
import json
import subprocess
import tempfile
import os
import base64
import mimetypes

from urllib.parse import quote as urlencode

from . import util
from .common import output

import boto3
import botocore

s3 = boto3.resource("s3")
s3c = boto3.client("s3")
default_region = "eu-central-1"

def s3url(bucket, region, path):
    return f"https://{bucket}.s3.{region}.amazonaws.com/{path}"

def url(o):
    return s3url(bucket=o.bucket_name, region=default_region, path=urlencode(o.key))

def s3exists(obj):
    try:
        obj.load()
        return True
    except botocore.exceptions.ClientError as e:
        if e.response["Error"]["Code"] != "404":
            raise
    return False

class Thumbnail:
    bucket = s3.Bucket("rootmos-static")
    bucket_region = default_region

    def __init__(self, id):
        self.id = id
        self._obj = self.bucket.Object(f"thumbnails/{self.id}.jpg")
        self.url = s3url(bucket=self._obj.bucket_name, region=self.__class__.bucket_region, path=self._obj.key)

    @property
    def exists(self):
        return s3exists(self._obj)

    @staticmethod
    def generate(source, output):
        cmdline = [ "ffmpeg" ]
        cmdline += [ "-i", source ]
        cmdline += [ "-vf", "select=eq(n\\,0)" ]
        cmdline += [ "-frames:v", "1", "-update", "1" ]
        cmdline += [ "-y", output ]
        cmdline += [ "-loglevel", "quiet" ]
        subprocess.check_call(cmdline)

    @property
    def base64(self):
        return str(base64.b64encode(self._obj.get()["Body"].read()), "UTF-8")

    @property
    def content_type(self):
        return "image/jpeg"

    def upload(self, source):
        with tempfile.TemporaryDirectory() as tmp:
            output = os.path.join(tmp, "thumb.jpg")
            self.__class__.generate(source, output)
            self._obj.upload_file(output, ExtraArgs={
                "ACL": "public-read",
                "ContentType": self.content_type
            })

    def ensure(self, obj):
        if not self.exists:
            with tempfile.TemporaryDirectory() as tmp:
                _, ext = os.path.splitext(obj.key)
                src = os.path.join(tmp, f"source.{ext}")
                obj.download_file(src)
                self.upload(src)
        return self

class Meta:
    bucket = s3.Bucket("rootmos-static")
    bucket_region = default_region

    TEMPLATE = { "title": None, "description": None }

    def __init__(self, id):
        self.id = id
        self._obj = self.bucket.Object(f"meta/{self.id}.json")

    @property
    def exists(self):
        return s3exists(self._obj)

    def load(self):
        if self.exists:
            return json.loads(self._obj.get()["Body"].read())
        else:
            return Meta.TEMPLATE

    def edit(self):
        m = util.edit(self.load())
        self._obj.put(Body=json.dumps(m).encode("UTF-8"), ACL="private")
        return m

def id_from_obj(obj):
    if obj.checksum_sha256 is not None:
        return obj.checksum_sha256[:7]
    elif obj.checksum_sha1 is not None:
        return obj.checksum_sha1[:7]
    else:
        return hashlib.sha1(url(obj).encode("UTF-8")).hexdigest()[:7]

def render(o, generate_thumbnails=None, embed_thumbnails=False):
    obj = o.Object()
    id_ = id_from_obj(obj)

    thumbnail = Thumbnail(id_)
    if generate_thumbnails:
        thumbnail = thumbnail.ensure(obj)

    m = Meta(id_).load()

    return {
        "id": id_,
        "url": url(o),
        "content_type": obj.content_type,
        "last_modified": o.last_modified.isoformat(),
        "thumbnail": {
            "url": thumbnail.url,
            "base64": thumbnail.base64 if embed_thumbnails else None,
            "content_type": thumbnail.content_type,
        },
        **m
    }

def objects(bucket, prefix=None):
    bucket = s3.Bucket(bucket)

    for o in bucket.objects.all():
        if prefix and not o.key.startswith(prefix):
            continue
        yield o

def parse_args():
    parser = argparse.ArgumentParser(description="Grab metadata about files stored on s3")

    subparsers = parser.add_subparsers(dest="cmd", required=True)

    list_cmd = subparsers.add_parser("list")
    list_cmd.add_argument("-o", "--output", metavar="OUTPUT")
    list_cmd.add_argument("-G", "--generate-thumbnails", action="store_true")
    list_cmd.add_argument("-e", "--embed-thumbnails", action="store_true")
    list_cmd.add_argument("bucket", metavar="BUCKET")
    list_cmd.add_argument("prefix", metavar="PREFIX", nargs="?")

    fix_cmd = subparsers.add_parser("fix")

    thumbnail_cmd = subparsers.add_parser("thumbnail")
    thumbnail_cmd.add_argument("source", metavar="SOURCE")
    thumbnail_cmd.add_argument("output", metavar="OUTPUT")

    meta_cmd = subparsers.add_parser("meta")
    meta_cmd.add_argument("id", metavar="ID")

    upload_cmd = subparsers.add_parser("upload")
    upload_cmd.add_argument("-e", "--edit", action="store_true")
    upload_cmd.add_argument("-f", "--force", action="store_true")
    upload_cmd.add_argument("-p", "--prefix", metavar="PREFIX")
    upload_cmd.add_argument("bucket", metavar="BUCKET")
    upload_cmd.add_argument("file", metavar="FILE")

    return parser.parse_args()

def do_list(args):
    os = []
    for o in objects(args.bucket, prefix=args.prefix):
        os.append(render(o,
            generate_thumbnails=args.generate_thumbnails,
            embed_thumbnails=args.embed_thumbnails,
        ))

    with output(args.output) as f:
        f.write(json.dumps(os))

def do_thumbnail(args):
    Thumbnail.generate(source=args.source, output=args.output)

def do_meta(args):
    Meta(args.id).edit()

def do_upload(args):
    with open(args.file, "rb") as f:
        sha256 = hashlib.file_digest(f, "SHA256")
        sha256_b64 = str(base64.b64encode(sha256.digest()), "UTF-8")

    if args.prefix is None:
        key = os.path.basename(args.file)
    else:
        key = f"{args.prefix}/{os.path.basename(args.file)}"

    skip_upload = False
    if not args.force:
        try:
            obj = s3c.head_object(Bucket=args.bucket, Key=key + "a", ChecksumMode="ENABLED")
            if obj.get("ChecksumSHA256") == sha256_b64:
                skip_upload = True
        except botocore.exceptions.ClientError as e:
            if e.response["Error"]["Code"] != "404":
                raise

    if not skip_upload:
        mt, _ = mimetypes.guess_type(args.file)

        with open(args.file, "rb") as f:
            s3c.put_object(Bucket=args.bucket, Key=key,
                Body = f,
                ContentType = mt,
                ChecksumSHA256 = sha256_b64,
                ACL = "public-read",
            )

    obj = s3.Object(args.bucket, key)
    id_ = id_from_obj(obj)
    Thumbnail(id_).ensure(obj)

    print(id_)

    if args.edit:
        Meta(id_).edit()

def main():
    args = parse_args()

    if args.cmd == "list":
        return do_list(args)
    elif args.cmd == "thumbnail":
        return do_thumbnail(args)
    elif args.cmd == "meta":
        return do_meta(args)
    elif args.cmd == "upload":
        return do_upload(args)
    else:
        raise NotImplementedError(args.cmd)
