import argparse
import json
import os
import sys

import boto3
from github import Github

def parse_args():
    parser = argparse.ArgumentParser(description="Grab project metadata")

    parser.add_argument("--profile")

    parser.add_argument("--user")
    parser.add_argument("projects_spec", metavar="PROJECTS_SPEC")

    return parser.parse_args()

def fetch_github_token(args):
    arn = os.environ["GITHUB_TOKEN_ARN"]
    session = boto3.Session(profile_name=args.profile)
    sm = session.client(service_name="secretsmanager", region_name=arn.split(":")[3])
    return sm.get_secret_value(SecretId=arn)["SecretString"]

def main():
    args = parse_args()

    g = Github(fetch_github_token(args))

    user = args.user
    if user is None:
        user = g.get_user().login

    with open(args.projects_spec, "r") as f:
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
            P["last_activity"] = r.pushed_at.isoformat()

        if "date_created" not in P:
            P["date_created"] = r.created_at.isoformat()

        ps[P["name"]] = P
    print(json.dumps(list(ps.values())))
