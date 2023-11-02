import argparse
import json
import sys

import boto3
from .common import output

import tasks.list

def parse_args():
    parser = argparse.ArgumentParser(description="Grab project metadata")

    subparsers = parser.add_subparsers(dest="cmd")

    gallery_cmd = subparsers.add_parser("gallery")
    gallery_cmd.add_argument("project")
    gallery_cmd.add_argument("bucket")
    gallery_cmd.add_argument("-o", "--output")

    preamble_cmd = subparsers.add_parser("preamble")
    preamble_cmd.add_argument("project")
    preamble_cmd.add_argument("bucket")
    preamble_cmd.add_argument("-o", "--output")

    return parser.parse_args()

def main():
    args = parse_args()

    if args.cmd == "gallery":
        gs = list(tasks.list.objects(args.bucket, prefix=f"projects/{args.project}/"))
        with output(args.output) as f:
            f.write(json.dumps(gs))
    elif args.cmd == "preamble":
        s3 = boto3.resource("s3")
        o = s3.Bucket(args.bucket).Object(f"{args.project}/latest/www/preamble.md")
        with output(args.output, mode="wb") as f:
            o.download_fileobj(f)
