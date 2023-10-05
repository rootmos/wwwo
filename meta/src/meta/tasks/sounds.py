import boto3
import json
import argparse

from concurrent.futures import ThreadPoolExecutor

from meta.common import output

def parse_args():
    parser = argparse.ArgumentParser(description="Grab metadata about sounds stored on s3")
    parser.add_argument("-o", "--output")
    parser.add_argument("--prefix")
    return parser.parse_args()

def main():
    args = parse_args()

    s3 = boto3.resource("s3")

    pool = ThreadPoolExecutor(8)
    bucket = s3.Bucket("rootmos-sounds")
    os = filter(lambda o: o.key.endswith(".json"), bucket.objects.all())
    if args.prefix:
        os = filter(lambda o: o.key.startswith(args.prefix), os)
    else:
        os = filter(lambda o: "/" not in o.key, os)
    ss = pool.map(lambda o: json.loads(o.get()["Body"].read()), os)
    with output(args.output) as f:
        f.write(json.dumps(list(ss), separators=(',', ':')))
