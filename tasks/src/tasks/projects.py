import argparse
import json
import os
import sys
import datetime

from .common import fetch_secret, output

import requests
from github import Github

def parse_args():
    parser = argparse.ArgumentParser(description="Grab projects metadata")

    parser.add_argument("-o", "--output")

    parser.add_argument("--user")
    parser.add_argument("projects_spec", metavar="PROJECTS_SPEC")

    return parser.parse_args()

def github(projects):
    g = Github(fetch_secret(os.environ["GITHUB_TOKEN_ARN"]))
    user = g.get_user().login

    ps = {}
    for p in projects:
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

        bs = []
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
            bs.append({
                "name": name,
                "commit": sha1,
                "date": last_commit_date.isoformat(),
            })
        P["branches"] = bs
        P["last_activity"] = most_recent_commit_date.isoformat()

        P["date_created"] = r.created_at.isoformat()

        P["stars"] = len(list(r.get_stargazers()))

        if "favorite" not in P:
            P["favorite"] = False

        ps[P["name"]] = P

    return ps

def sourcehut(projects):
    token = fetch_secret(os.environ["SOURCEHUT_TOKEN_ARN"])

    h = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json",
        "Content-Type": "application/json",
    }

    ps = {}
    cursor = "null"
    while True:
        query = f"""
{{
   repositories(cursor: {cursor}) {{
      cursor
      results {{
        name, description, created, updated, visibility
        owner {{
          canonicalName
        }}
      }}
    }}
}}"""
        body = { "query": query }
        rsp = requests.post("https://git.sr.ht/query", headers=h, data=json.dumps(body))
        j = json.loads(rsp.content)
        rs = j["data"]["repositories"]

        for r in rs["results"]:
            name = r["name"]

            def m(p):
                if isinstance(p, str):
                    return p == name
                elif isinstance(p, dict):
                    return p["name"] == name
            try:
                p = next(filter(m, projects))
            except StopIteration:
                continue
            if isinstance(p, str):
                p = { "name": p }

            ps[name] = {
                "name": name,
                "description": r["description"],
                "date_created": r["created"],
                "last_activity": r["updated"],
                "url": "https://git.sr.ht/" + r["owner"]["canonicalName"] + "/" + name,
                "favorite": p.get("favorite", False),
            }

        cursor = rs.get("cursor")
        if not cursor:
            break
        else:
            cursor = f"\"{cursor}\""

    return ps

def main():
    args = parse_args()

    with open(args.projects_spec, "r") as f:
        raw = json.loads(f.read())

    ps = github(raw.get("github", {}))
    ps |= sourcehut(raw.get("sourcehut", {}))

    with output(args.output) as f:
        json.dump(list(ps.values()), f)
