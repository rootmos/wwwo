import argparse
import pathlib
import urllib
import os

import magic

from .util import eprint

import boto3

def parse_args():
    parser = argparse.ArgumentParser(description="Upload directory to s3")

    parser.add_argument("-n", "--dry-run", action="store_true")

    parser.add_argument("root")
    parser.add_argument("target", metavar="S3_URL")

    return parser.parse_args()

def parse_s3_url(url):
    p = urllib.parse.urlparse(url, scheme="s3")
    assert(p.scheme == "s3")
    return p.netloc, p.path.lstrip("/")

def main():
    args = parse_args()

    bucket, prefix = parse_s3_url(args.target)

    s3 = boto3.resource('s3')
    for p in pathlib.Path(args.root).glob("**/*"):
        if p.is_dir():
            continue
        rel = os.path.relpath(p, start=args.root)
        key = os.path.join(prefix, rel)
        o = s3.Object(bucket, key)

        mt = magic.from_file(p, mime=True)

        if args.dry_run:
            print(f"{p} -> {o} ({mt})")
        else:
            eprint(f"{p} -> {o}")
            o.upload_file(p, ExtraArgs = {
                "ACL": "public-read",
                "ContentType": mt,
            })
