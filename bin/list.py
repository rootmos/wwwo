#!/usr/bin/env python3

import boto3
import json
import argparse
from urllib.parse import quote as urlencode

def url(o):
    return f"https://{o.bucket_name}.s3.eu-central-1.amazonaws.com/{urlencode(o.key)}"

def render(o):
    return {
        "url": url(o),
        "content_type": o.Object().content_type,
        "last_modified": o.last_modified.isoformat(),
    }

def parse_args():
    parser = argparse.ArgumentParser(description="Grab metadata about files stored on s3")
    parser.add_argument("--prefix", action="store")
    parser.add_argument("--profile", action="store")
    parser.add_argument("bucket")
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_args()
    session = boto3.Session(profile_name=args.profile)
    s3 = session.resource("s3")
    bucket = s3.Bucket(args.bucket)
    os = bucket.objects.all()

    if args.prefix:
        os = filter(lambda o: o.key.startswith(args.prefix), os)

    print(json.dumps(list(map(render, os))))
