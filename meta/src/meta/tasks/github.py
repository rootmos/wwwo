import itertools
import json
import argparse
import os

import boto3
from github import Github

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
    return cs

def parse_args():
    parser = argparse.ArgumentParser(description="Fetch recent GitHub activity")

    parser.add_argument("--profile")

    parser.add_argument("--commits", metavar='N', dest="commits", type=int, default=10)
    parser.add_argument("user")

    return parser.parse_args()

def fetch_github_token(args):
    arn = os.environ["GITHUB_TOKEN_ARN"]
    session = boto3.Session(profile_name=args.profile)
    sm = session.client(service_name="secretsmanager", region_name=arn.split(":")[3])
    return sm.get_secret_value(SecretId=arn)["SecretString"]

def main():
    args = parse_args()

    g = Github(fetch_github_token(args))

    u = g.get_user(args.user)
    print(json.dumps(commits(u, args.commits)))
