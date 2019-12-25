#!/usr/bin/env python3

import boto3
import json
import argparse
from urllib.parse import quote as urlencode

def url(k):
    return f"https://{bucket.name}.ams3.cdn.digitaloceanspaces.com/{urlencode(k)}"

def render(o):
    return { "url": url(o.key), "content_type": o.Object().content_type }

def parse_args():
    parser = argparse.ArgumentParser(description="Grab metadata about files stored on s3")
    parser.add_argument("--prefix", action="store")
    parser.add_argument("--profile", action="store")
    parser.add_argument("bucket")
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_args()
    session = boto3.Session(profile_name=args.profile)
    s3 = session.resource("s3", endpoint_url="https://ams3.digitaloceanspaces.com")
    bucket = s3.Bucket(args.bucket)
    os = bucket.objects.all()

    if args.prefix:
        os = filter(lambda o: o.key.startswith(args.prefix), os)

    print(json.dumps(list(map(render, os))))
