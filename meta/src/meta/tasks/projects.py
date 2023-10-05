import argparse
import json
import os
import sys

from meta.common import fetch_secret, output

from github import Github

def parse_args():
    parser = argparse.ArgumentParser(description="Grab projects metadata")

    parser.add_argument("-o", "--output")

    parser.add_argument("--user")
    parser.add_argument("projects_spec", metavar="PROJECTS_SPEC")

    return parser.parse_args()

def main():
    args = parse_args()

    g = Github(fetch_secret(os.environ["GITHUB_TOKEN_ARN"]))

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

    with output(args.output) as f:
        f.write(json.dumps(list(ps.values())))
