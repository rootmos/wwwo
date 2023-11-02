import argparse
import hashlib
import os
import pathlib
import urllib
import mimetypes

import boto3

from .util import eprint

def parse_args():
    parser = argparse.ArgumentParser(description="Upload directory to s3")

    parser.add_argument("-n", "--dry-run", action="store_true")

    parser.add_argument("-H", "--htmls")

    parser.add_argument("root")
    parser.add_argument("target", metavar="S3_URL")

    return parser.parse_args()

def parse_s3_url(url):
    p = urllib.parse.urlparse(url, scheme="s3")
    assert(p.scheme == "s3")
    return p.netloc, p.path.lstrip("/")

def main():
    args = parse_args()

    mimetypes.init()
    mimetypes.add_type("image/x-icon", ".ico") # https://en.wikipedia.org/wiki/Favicon#Standardization

    bucket, prefix = parse_s3_url(args.target)

    htmls = None
    if args.htmls is not None:
        htmls = open(args.htmls, "w")

    s3 = boto3.resource('s3')
    for p in pathlib.Path(args.root).glob("**/*"):
        if p.is_dir():
            continue
        rel = os.path.relpath(p, start=args.root)
        key = os.path.join(prefix, rel)
        o = s3.Object(bucket, key)

        with open(p, "rb") as f:
            md5 = hashlib.file_digest(f, "md5").hexdigest()

        (mt, _) = mimetypes.guess_type(p)

        if htmls and mt.startswith("text/html"):
            htmls.write(key)
            htmls.write("\n")

        l = f"{p} -> {o} ({mt}) (MD5:{md5})"
        if args.dry_run:
            eprint("DRYRUN: " + l)
        else:
            eprint(l)
            o.upload_file(p, ExtraArgs = {
                "ACL": "public-read",
                "ContentType": mt,
            })

    if htmls:
        htmls.close()
