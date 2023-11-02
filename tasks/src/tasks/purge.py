import argparse
import requests

from .util import eprint

def parse_args():
    parser = argparse.ArgumentParser(description="Purge cache")

    parser.add_argument("base_url", metavar="BASE_URL")
    parser.add_argument("paths", metavar="PATH", nargs="*")

    return parser.parse_args()

def main():
    args = parse_args()

    for p in args.paths:
        url = f"{args.base_url}/{p}"
        eprint(f"purging: {url}")
        rsp = requests.head(url, headers={"Cache-Purge": "true"})
        rsp.raise_for_status()
        eprint(f"  ETag: {rsp.headers['ETag']}")

