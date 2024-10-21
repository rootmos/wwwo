import argparse
import itertools
import json
import os
import re

from github import Github
import requests

from .common import fetch_secret, output

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
    token = os.environ.get("SOURCEHUT_TOKEN")
    if token is None:
        token = fetch_secret(os.environ["SOURCEHUT_TOKEN_ARN"])

    def graphql(query):
        query = re.sub(r"\s+", " ", query)
        h = {
            "Authorization": f"Bearer {token}",
            "Accept": "application/json",
            "Content-Type": "application/json",
        }

        body = { "query": query }
        rsp = requests.post("https://git.sr.ht/query", headers=h, json=body)
        rsp.raise_for_status()
        return rsp.json()

    def accessible_repositories():
        cursor = "null"
        while True:
            rsp = graphql("""
                {
                    repositories(cursor: %s) {
                        cursor
                        results {
                            name, description, visibility
                            owner {
                              canonicalName
                            }
                        }
                    }
                }""" % cursor
            )
            rs = rsp["data"]["repositories"]

            for r in rs["results"]:
                yield {
                    "name": r["name"],
                    "description": r["description"],
                    "visibility": r["visibility"],
                    "url": "https://git.sr.ht/" + r["owner"]["canonicalName"] + "/" + r["name"],
                }

            cursor = rs.get("cursor")
            if not cursor:
                break
            else:
                cursor = f"\"{cursor}\""

    for repo in accessible_repositories():
        print(repo)

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
