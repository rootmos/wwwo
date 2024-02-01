import argparse
import hashlib
import json
import subprocess
import tempfile
import os

from urllib.parse import quote as urlencode

from .common import output

import boto3
import botocore

s3 = boto3.resource("s3")

def s3url(bucket, region, path):
    return f"https://{bucket}.s3.{region}.amazonaws.com/{path}"

class Thumbnail:
    bucket = s3.Bucket("rootmos-static")
    bucket_region = "eu-central-1"

    def __init__(self, id):
        self.id = id
        self._obj = self.bucket.Object(f"thumbnails/{self.id}.jpg")
        self.url = s3url(bucket=self._obj.bucket_name, region=self.__class__.bucket_region, path=self._obj.key)

    @property
    def exists(self):
        try:
            self._obj.load()
            return True
        except botocore.exceptions.ClientError as e:
            if e.response["Error"]["Code"] != "404":
                raise
            return False

    @staticmethod
    def generate(source, output):
        cmdline = [ "ffmpeg" ]
        cmdline += [ "-i", source ]
        cmdline += [ "-vf", "select=eq(n\\,0)" ]
        cmdline += [ "-frames:v", "1", "-update", "1" ]
        cmdline += [ "-y", output ]
        cmdline += [ "-loglevel", "quiet" ]
        subprocess.check_call(cmdline)

    def upload(self, source):
        with tempfile.TemporaryDirectory() as tmp:
            output = os.path.join(tmp, "thumb.jpg")
            self.__class__.generate(source, output)
            self._obj.upload_file(output, ExtraArgs={"ACL": "public-read"})

def ensure_thumbnail(obj):
    t = Thumbnail(id_from_obj(obj))
    if not t.exists:
        with tempfile.TemporaryDirectory() as tmp:
            _, ext = os.path.splitext(obj.key)
            src = os.path.join(tmp, f"source.{ext}")
            obj.download_file(src)
            t.upload(src)
    return t.url

def url(o):
    return s3url(bucket=o.bucket_name, region="eu-central-1", path=urlencode(o.key))

def id_from_obj(obj):
    if obj.checksum_sha256 is not None:
        return obj.checksum_sha256[:7]
    elif obj.checksum_sha1 is not None:
        return obj.checksum_sha1[:7]
    else:
        return hashlib.sha1(url(obj).encode("UTF-8")).hexdigest()[:7]

def render(o, generate_thumbnails=None):
    obj = o.Object()
    id_ = id_from_obj(obj)
    return {
        "id": id_,
        "url": url(o),
        "content_type": obj.content_type,
        "last_modified": o.last_modified.isoformat(),
        "thumbnail": ensure_thumbnail(obj) if generate_thumbnails else Thumbnail(id_).url,
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
    list_cmd.add_argument("bucket", metavar="BUCKET")
    list_cmd.add_argument("prefix", metavar="PREFIX", nargs="?")

    upload_cmd = subparsers.add_parser("upload")

    fix_cmd = subparsers.add_parser("fix")

    thumbnail_cmd = subparsers.add_parser("thumbnail")
    thumbnail_cmd.add_argument("source", metavar="SOURCE")
    thumbnail_cmd.add_argument("output", metavar="OUTPUT")

    return parser.parse_args()

def do_list(args):
    os = []
    for o in objects(args.bucket, prefix=args.prefix):
        os.append(render(o, generate_thumbnails=args.generate_thumbnails))

    with output(args.output) as f:
        f.write(json.dumps(os))

def do_thumbnail(args):
    Thumbnail.generate(source=args.source, output=args.output)

def main():
    args = parse_args()

    if args.cmd == "list":
        return do_list(args)
    elif args.cmd == "thumbnail":
        return do_thumbnail(args)
    else:
        raise NotImplementedError(args.cmd)
