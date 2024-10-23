import argparse
import datetime
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

def render_sourcehut_commit(c):
    return {
        "hash": c.id,
        "title": c.title,
        "url": c.url,
        "date": c.author.time.isoformat(timespec="seconds"),
        "repo": {
            "name": c.repo.name,
            "url": c.repo.url,
        }
    }

def fetch_from_sourcehut(author_name, after):
    api = sourcehut.API(token=sourcehut.token_from_env())

    commits = set()
    for repo in api.repositories():
        refs = repo.refs()
        for _, ref in refs.items():
            if ref.name == "HEAD" and ref.target in refs:
                continue
            for c in ref.log():
                if after and c.author.time < after:
                    break

                if c.author.name != author_name:
                    continue

                commits.add(c)

    return commits

def parse_args():
    parser = argparse.ArgumentParser(description="Fetch recent GitHub activity")

    parser.add_argument("-o", "--output")

    parser.add_argument("--days", metavar='N', type=int, default=7)

    parser.add_argument("--github-username")
    parser.add_argument("--sourcehut-author-name")

    return parser.parse_args()

def main():
    args = parse_args()

    after = None
    if args.days:
        after = datetime.datetime.now().astimezone() - datetime.timedelta(days=args.days)

    commits = []

    if args.github_username:
        g = Github(fetch_secret(os.environ["GITHUB_TOKEN_ARN"]))
        user = g.get_user(args.github_username)
        commits += from_github(user, args.commits)

    if args.sourcehut_author_name:
        cs = fetch_from_sourcehut(author_name=args.sourcehut_author_name, after=after)
        commits += [ render_sourcehut_commit(c) for c in cs ]

    with output(args.output) as f:
        f.write(json.dumps(commits))
