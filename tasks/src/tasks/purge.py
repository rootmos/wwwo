import argparse
import requests

from .util import eprint, env

def parse_args():
    parser = argparse.ArgumentParser(description="Purge cache")

    parser.add_argument("--cache-purge-token", metavar="TOKEN", default=env("CACHE_PURGE_TOKEN"))
    parser.add_argument("--ratelimit-bypass-token", metavar="TOKEN", default=env("RATELIMIT_BYPASS_TOKEN"))

    parser.add_argument("base_url", metavar="BASE_URL")
    parser.add_argument("paths", metavar="PATH", nargs="*")

    return parser.parse_args()

def main():
    args = parse_args()

    for p in args.paths:
        url = f"{args.base_url}/{p}"
        eprint(f"purging: {url}")
        rsp = requests.head(url, headers={
            "X-Cache-Purge": args.cache_purge_token,
            "X-RateLimit-Bypass": args.ratelimit_bypass_token,
        })
        rsp.raise_for_status()
        if rsp.headers["X-Cache-Status"] != "BYPASS":
            raise RuntimeError(f"unable to purge: {url}")
        eprint(f"  ETag: {rsp.headers['ETag']}")
