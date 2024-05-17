import argparse
import json

from .common import output

import boto3

def parse_args():
    parser = argparse.ArgumentParser(description="Grab metadata about the resume stored on s3")

    parser.add_argument("--output", metavar="OUTPUT")

    return parser.parse_args()

def main():
    args = parse_args()

    s3 = boto3.resource("s3")
    obj = s3.Object("rootmos-static", "resume-gustav-behm.pdf")
    meta = obj.metadata

    with output(args.output) as f:
        f.write(json.dumps(meta))
