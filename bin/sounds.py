#!/usr/bin/env python3

import boto3
import json
import argparse
from concurrent.futures import ThreadPoolExecutor

def parse_args():
    parser = argparse.ArgumentParser(description="Grab metadata about files stored on s3")
    parser.add_argument("--prefix", action="store")
    parser.add_argument("--profile", action="store")
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_args()

    session = boto3.Session(profile_name=args.profile)
    s3 = session.resource("s3", endpoint_url="https://ams3.digitaloceanspaces.com")

    pool = ThreadPoolExecutor(8)
    bucket = s3.Bucket("rootmos-sounds")
    os = filter(lambda o: o.key.endswith(".json"), bucket.objects.all())
    if args.prefix:
        os = filter(lambda o: o.key.startswith(args.prefix), os)
    else:
        os = filter(lambda o: "/" not in o.key, os)
    ss = pool.map(lambda o: json.loads(o.get()["Body"].read()), os)
    print(json.dumps(list(ss), separators=(',', ':')))
