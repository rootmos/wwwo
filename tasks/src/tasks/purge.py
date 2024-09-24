import argparse
import requests
import time

from .util import eprint, env

def parse_args():
    parser = argparse.ArgumentParser(description="Purge cache")

    parser.add_argument("--cache-purge-token", metavar="TOKEN", default=env("CACHE_PURGE_TOKEN"))
    parser.add_argument("--rate-limit", type=int, default=env("RATE_LIMIT", "2"))

    parser.add_argument("base_url", metavar="BASE_URL")
    parser.add_argument("paths", metavar="PATH", nargs="*")

    return parser.parse_args()

def main():
    args = parse_args()
    delay = args.rate_limit/2

    for p in args.paths:
        url = f"{args.base_url}/{p}"
        eprint(f"purging: {url}")
        rsp = requests.head(url, headers={"X-Cache-Purge": args.cache_purge_token})
        rsp.raise_for_status()
        if rsp.headers["X-Cache-Status"] != "BYPASS":
            raise RuntimeError(f"unable to purge: {url}")
        eprint(f"  ETag: {rsp.headers['ETag']}")
        time.sleep(delay)
