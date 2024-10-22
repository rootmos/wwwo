import os

import requests

from .common import fetch_secret

def find_cursor(x):
    def go(x):
        if isinstance(x, dict):
            for k, v in x.items():
                if k == "cursor":
                    yield v
                else:
                    yield from go(v)
        elif isinstance(x, list):
            for v in x:
                yield from go(v)

    cs = list(go(x))
    if len(cs) == 0:
        return None
    elif len(cs) == 1:
        return cs[0]
    else:
        raise RuntimeError("multiple cursors found", x)

class API:
    def __init__(self):
        token = os.environ.get("SOURCEHUT_TOKEN")
        if token is None:
            arn = os.environ["SOURCEHUT_TOKEN_ARN"]
            token = fetch_secret(arn)

        self.session = requests.Session()

        self.session.headers.update({
            "Authorization": f"Bearer {token}",
            "Accept": "application/json",
            "Content-Type": "application/json",
        })

    def graphql(self, query):
        # query = re.sub(r"\s+", " ", query)
        rsp = self.session.post("https://git.sr.ht/query", json={ "query": query })
        if rsp.status_code == 422:
            j = rsp.json()
            if "errors" in j:
                raise RuntimeError("GraphQL errors", j["errors"])
        rsp.raise_for_status()
        return rsp.json()["data"]

    def yield_from_cursor(self, query, f, metavar="$cursor"):
        cursor = "null"
        while cursor:
            q = query.replace(metavar, cursor)
            data = self.graphql(q)
            yield from f(data)
            cursor = find_cursor(data)
            if cursor:
                cursor = '"' + cursor + '"'

    def repositories(self):
        query = """{
            repositories(cursor: $cursor) {
                cursor
                results {
                    name, description, visibility
                    owner {
                        canonicalName
                        ... on User {
                            username
                        }
                    }
                }
            }
        }"""

        def f(data):
            for raw in data["repositories"]["results"]:
                yield Repository(self, raw)

        yield from self.yield_from_cursor(query, f)

    def repository(self, username, name):
        query = """{
            user(username: "%s") {
                repository(name: "%s") {
                    name, description, visibility

                    owner {
                        canonicalName
                        ... on User {
                            username
                        }
                    }
                }
            }
        }""" % (username, name)

        data = self.graphql(query)
        raw = data["user"]["repository"]
        if raw is not None:
            return Repository(self, raw)

class Repository:
    def __init__(self, api, raw):
        self.api = api

        self.name = raw["name"]
        self.description = raw["description"]
        self.visibility = raw["visibility"]
        self.owner = raw["owner"]["username"]
        self.url = "https://git.sr.ht/" + raw["owner"]["canonicalName"] + "/" + raw["name"]

    def __str__(self):
        return f"{self.owner}/{self.name}"

    def refs(self):
        query = """{
            user(username: "%s") {
                repository(name: "%s") {
                    references(cursor: $cursor) {
                        cursor
                        results {
                            name, target
                        }
                    }
                }
            }
        }""" % (self.owner, self.name)

        def f(data):
            for raw in data["user"]["repository"]["references"]["results"]:
                yield Ref(self, raw)

        refs = {}
        for ref in self.api.yield_from_cursor(query, f):
            refs[ref.name] = ref
        return refs

class Ref:
    def __init__(self, repo, raw):
        self.api = repo.api
        self.repo = repo

        self.name = raw["name"]
        self.target = raw["target"]

    def __str__(self):
        return f"{self.name} ({self.target})"

    def __repr__(self):
        return f"{self.name} ({self.target})"

    def log(self):
        query = """{
            user(username: "%s") {
                repository(name: "%s") {
                    log(cursor: $cursor, from: "%s") {
                        cursor
                        results {
                            id, message
                        }
                    }
                }
            }
        }""" % (self.repo.owner, self.repo.name, self.target)

        def f(data):
            for raw in data["user"]["repository"]["log"]["results"]:
                yield Commit(self, raw)

        yield from self.api.yield_from_cursor(query, f)

class Commit:
    def __init__(self, ref, raw):
        self.api = ref.api
        self.repo = ref.repo
        self.ref = ref

        self.id = raw["id"]
        self.message = raw["message"]

        lines = self.message.splitlines()
        if lines:
            self.title = lines[0]
        else:
            self.title = None

    def __str__(self):
        return self.id
