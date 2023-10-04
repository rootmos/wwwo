import argparse
import json
import sys

import boto3

import meta.tasks.list

def parse_args():
    parser = argparse.ArgumentParser(description="Grab project metadata")

    parser.add_argument("--profile")

    subparsers = parser.add_subparsers(dest="cmd")

    gallery_cmd = subparsers.add_parser("gallery")
    gallery_cmd.add_argument("project")
    gallery_cmd.add_argument("bucket")

    preamble_cmd = subparsers.add_parser("preamble")
    preamble_cmd.add_argument("project")
    preamble_cmd.add_argument("bucket")

    return parser.parse_args()

def main():
    args = parse_args()

    if args.cmd == "gallery":
        gs = list(meta.tasks.list.objects(args.bucket, prefix=f"projects/{args.project}/", profile=args.profile))
        print(json.dumps(gs))
    elif args.cmd == "preamble":
        session = boto3.Session(profile_name=args.profile)
        s3 = session.resource("s3")
        o = s3.Bucket(args.bucket).Object(f"{args.project}/latest/www/preamble.md")
        o.download_fileobj(sys.stdout.buffer)
