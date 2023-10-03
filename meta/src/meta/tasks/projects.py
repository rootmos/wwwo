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
        if isinstance(p, dict):
            P = p
        elif isinstance(p, str):
            P = { "name": p }
        else:
            raise RuntimeError("unsupported project definition")

        r = g.get_repo(f"{user}/{P['name']}")

        if "description" not in P:
            P["description"] = r.description

        if "url" not in P:
            P["url"] = r.html_url

        if "last_activity" not in P:
            P["last_activity"] = r.pushed_at.isoformat() + "Z"

        if "date_created" not in P:
            P["date_created"] = r.created_at.isoformat() + "Z"

        ps[P["name"]] = P
    print(json.dumps(list(ps.values())))
