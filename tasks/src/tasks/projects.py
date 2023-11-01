import argparse
import json
import os
import sys
import datetime

from .common import fetch_secret, output

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

        bs = {}
        most_recent_commit_date = datetime.datetime.fromtimestamp(0).astimezone()
        for ref in r.get_git_refs():
            if not ref.ref.startswith("refs/heads/"):
                continue
            sha1 = ref.object.sha
            h = r.get_commit(sha1)
            name = ref.ref.removeprefix("refs/heads/")
            last_commit_date = h.commit.author.date
            if last_commit_date > most_recent_commit_date:
                most_recent_commit_date = last_commit_date
            bs[name] = {
                "commit": sha1,
                "date": last_commit_date.isoformat(),
            }
        P["branches"] = bs
        P["last_activity"] = most_recent_commit_date.isoformat()

        P["date_created"] = r.created_at.isoformat()

        P["stars"] = len(list(r.get_stargazers()))

        ps[P["name"]] = P

    with output(args.output) as f:
        f.write(json.dumps(list(ps.values())))
