import collections
import argparse
import datetime
import json
import os

import github

from .common import fetch_secret, output
from . import sourcehut

def github_token_from_env():
    token = os.environ.get("GITHUB_TOKEN")
    if token is None:
        arn = os.environ["GITHUB_TOKEN_ARN"]
        token = fetch_secret(arn)
    return token

def walk_github_repo(repo, author_name, after):
    visited = set()
    found = set()
    unvisited = collections.deque()

    for branch in repo.get_branches():
        unvisited.append(branch.commit)

    while unvisited:
        c = unvisited.pop()

        if c in visited:
            continue
        visited.add(c)

        if after and c.commit.author.date < after:
            continue

        if c.commit.author.name == author_name:
            found.add(c)

        for p in c.parents:
            if p in visited:
                continue
            unvisited.append(p)

    return found

def render_github_commit(r, c):
    return {
        "hash": c.sha,
        "title": c.commit.message.splitlines()[0],
        "url": c.html_url,
        "date": c.commit.author.date.isoformat(timespec="seconds"),
        "repo": {
            "name": r.name,
            "url": r.html_url,
            "public": r.visibility == "public",
        }
    }

def fetch_from_github(author_name, username, after):
    api = github.Github(login_or_token=github_token_from_env())

    commits = collections.deque()
    for repo in api.get_user(username).get_repos():
        print(f"processing GitHub repo: {repo.name}")
        for commit in walk_github_repo(repo, author_name, after):
            commits.append(render_github_commit(repo, commit))

    return list(commits)

def render_sourcehut_commit(c):
    return {
        "hash": c.id,
        "title": c.title,
        "url": c.url,
        "date": c.author.time.isoformat(timespec="seconds"),
        "repo": {
            "name": c.repo.name,
            "url": c.repo.url,
            "public": c.repo.visibility == "PUBLIC",
        }
    }

def fetch_from_sourcehut(author_name, after):
    api = sourcehut.API(token=sourcehut.token_from_env())

    commits = set()
    for repo in api.repositories():
        print(f"processing sourcehut repo: {repo.name}")
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

    return [ render_sourcehut_commit(c) for c in cs ]

def parse_args():
    parser = argparse.ArgumentParser(description="Fetch recent GitHub activity")

    parser.add_argument("-o", "--output")

    parser.add_argument("--days", metavar='N', type=int, default=7)

    parser.add_argument("--author-name", required=True)

    parser.add_argument("--github-username")
    parser.add_argument("--sourcehut", action="store_true")

    return parser.parse_args()

def main():
    args = parse_args()

    after = None
    if args.days:
        after = datetime.datetime.now().astimezone() - datetime.timedelta(days=args.days)

    commits = []

    if args.github_username:
        commits += fetch_from_github(author_name=args.author_name, username=args.github_username, after=after)

    if args.sourcehut:
        commits += fetch_from_sourcehut(author_name=args.author_name, after=after)

    with output(args.output) as f:
        f.write(json.dumps(commits))
