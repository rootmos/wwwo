import json
import argparse
import hashlib

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

    parser.add_argument("-o", "--output")

    parser.add_argument("--prefix")
    parser.add_argument("bucket")

    return parser.parse_args()

def main():
    args = parse_args()

    os = list(objects(args.bucket, prefix=args.prefix))
    with output(args.output) as f:
        f.write(json.dumps(os))
