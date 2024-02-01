import argparse
import hashlib
import json
import subprocess

from urllib.parse import quote as urlencode

from .common import output

import boto3

def url(o):
    return f"https://{o.bucket_name}.s3.eu-central-1.amazonaws.com/{urlencode(o.key)}"

def render(o):
    obj = o.Object()

    if obj.checksum_sha256 is not None:
        id_ = obj.checksum_sha256[:7]
    elif obj.checksum_sha1 is not None:
        id_ = obj.checksum_sha1[:7]
    else:
        id_ = hashlib.sha1(url(o).encode("UTF-8")).hexdigest()[:7]

    return {
        "id": id_,
        "url": url(o),
        "content_type": obj.content_type,
        "last_modified": o.last_modified.isoformat(),
    }

def objects(bucket, prefix=None):
    s3 = boto3.resource("s3")
    bucket = s3.Bucket(bucket)

    for o in bucket.objects.all():
        if prefix and not o.key.startswith(prefix):
            continue
        yield render(o)

def parse_args():
    parser = argparse.ArgumentParser(description="Grab metadata about files stored on s3")

    subparsers = parser.add_subparsers(dest="cmd", required=True)

    list_cmd = subparsers.add_parser("list")
    list_cmd.add_argument("-o", "--output")
    list_cmd.add_argument("bucket")
    list_cmd.add_argument("prefix", nargs="?")

    upload_cmd = subparsers.add_parser("upload")

    fix_cmd = subparsers.add_parser("fix")

    thumbnail_cmd = subparsers.add_parser("thumbnail")
    thumbnail_cmd.add_argument("source", metavar="SOURCE")
    thumbnail_cmd.add_argument("output", metavar="OUTPUT")

    return parser.parse_args()

def do_list(args):
    os = list(objects(args.bucket, prefix=args.prefix))
    with output(args.output) as f:
        f.write(json.dumps(os, indent=2))

def do_thumbnail(args):
    source = args.source
    output = args.output

    cmdline = [ "ffmpeg" ]
    cmdline += [ "-i", source ]
    cmdline += [ "-vf", "select=eq(n\\,0)" ]
    cmdline += [ "-frames:v", "1", "-update", "1" ]
    cmdline += [ "-y", output ]
    cmdline += [ "-loglevel", "quiet" ]
    subprocess.check_call(cmdline)

def main():
    args = parse_args()

    if args.cmd == "list":
        return do_list(args)
    elif args.cmd == "thumbnail":
        return do_thumbnail(args)
    else:
        raise NotImplementedError(args.cmd)
