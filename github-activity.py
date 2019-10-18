#!/usr/bin/env python3

from github import Github
import itertools
import json
import argparse
import os

with open(os.path.expanduser("~/.github_access_token"), "r") as f:
    token = f.read().split('\n')[0]

g = Github(token)

def commits(u, N):
    cs = []
    for e in u.get_public_events():
        if len(cs) > N: return cs

        d = {
            "event_id": e.id,
            "date": e.created_at.isoformat() + "Z",
            "repo":  e.repo.name,
            "repo_url":  e.repo.html_url,
        }

        if e.type == "PushEvent":
            p = e.payload
            for c in e.payload["commits"]:
                c = e.repo.get_commit(c["sha"])
                if c.author == u:
                    cs.append({ **d,
                        "type": "commit",
                        "sha": c.sha,
                        "url": c.html_url,
                        "message": c.commit.message,
                    })

if __name__ == "__main__":
    p = argparse.ArgumentParser(description="Fetch users recent GitHub activity")
    p.add_argument("user")
    p.add_argument("--commits", metavar='N', dest="commits", type=int, default=10)
    args = p.parse_args()

    u = g.get_user(args.user)
    with open(f"github-activity.{args.user}.commits.json", 'w') as f:
        f.write(json.dumps(commits(u, args.commits)))
