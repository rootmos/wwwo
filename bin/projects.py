#!/usr/bin/env python3

from github import Github
import json
import os
import sys

with open(os.path.expanduser("~/.github_access_token"), "r") as f:
    token = f.read().split('\n')[0]

g = Github(token)
user = "rootmos"

if __name__ == "__main__":
    with open(sys.argv[1], "r") as f:
        raw = json.loads(f.read())

    ps = {}
    for p in raw:
        if isinstance(p, str):
            r = g.get_repo(f"{user}/{p}")
            ps[p] = {
                "name": p,
                "description": r.description,
                "repository_url": r.html_url,
                "last_activity": r.pushed_at.isoformat() + "Z",
                "date_created": r.created_at.isoformat() + "Z",
            }
        else:
            raise RuntimeError("unsupported project definition")
    ps = sorted(ps.values(), key=(lambda p: p["last_activity"]))
    ps.reverse()
    print(json.dumps(ps))
