import argparse
import itertools
import json
import os

from github import Github

from .common import fetch_secret, output
from . import sourcehut

def from_github(u, N):
    cs = []
    for e in u.get_public_events():
        if len(cs) > N: return cs

        d = {
            "event_id": e.id,
            "date": e.created_at.isoformat(),
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
    return cs

def from_sourcehut():
    api = sourcehut.API()

    # for repo in api.repositories():
        # print(repo)

    repo = api.repository("rootmos", "scripts")
    for c in itertools.islice(repo.refs()["HEAD"].log(), 5):
        print(f"{c.id[:7]} {c.title}")

def parse_args():
    parser = argparse.ArgumentParser(description="Fetch recent GitHub activity")

    parser.add_argument("-o", "--output")

    parser.add_argument("--commits", metavar='N', dest="commits", type=int, default=10)

    parser.add_argument("--github")
    parser.add_argument("--sourcehut", action="store_true")

    return parser.parse_args()

def main():
    args = parse_args()

    commits = []

    if args.github:
        g = Github(fetch_secret(os.environ["GITHUB_TOKEN_ARN"]))
        user = g.get_user(args.github)
        commits += from_github(user, args.commits)

    if args.sourcehut:
        from_sourcehut()

    with output(args.output) as f:
        f.write(json.dumps(commits))
