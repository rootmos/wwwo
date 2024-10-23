import os
import datetime

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

def token_from_env():
    token = os.environ.get("SOURCEHUT_TOKEN")
    if token is None:
        arn = os.environ["SOURCEHUT_TOKEN_ARN"]
        token = fetch_secret(arn)
    return token

class API:
    def __init__(self, token):
        self.token = token

        self.session = requests.Session()
        self.session.headers.update({
            "Authorization": f"Bearer {token}",
            "Accept": "application/json",
            "Content-Type": "application/json",
        })

    def graphql(self, query):
        # query = re.sub(r"\s+", " ", query)
        # print("submitting query: " + query)
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
            if data is not None:
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
                            username, email
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
                            username, email
                        }
                    }
                }
            }
        }""" % (username, name)

        data = self.graphql(query)
        raw = data["user"]["repository"]
        if raw is not None:
            return Repository(self, raw)

    def me(self):
        query = """{
            me {
                username
                canonicalName
                email
            }
        }"""

        data = self.graphql(query)
        raw = data["me"]
        if raw is not None:
            return User(self, raw)

    def user(self, username):
        query = """{
            user(username: "%s") {
                username
                canonicalName
                email
            }
        }""" % username

        data = self.graphql(query)
        raw = data["user"]
        if raw is not None:
            return User(self, raw)

class Repository:
    def __init__(self, api, raw):
        self.api = api

        self.name = raw["name"]
        self.description = raw["description"]
        self.visibility = raw["visibility"]
        self.owner = User(api, raw["owner"])

        self.url = "https://git.sr.ht/" + self.owner.canonicalName + "/" + self.name

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
        }""" % (self.owner.username, self.name)

        def f(data):
            for raw in data["user"]["repository"]["references"]["results"]:
                yield Ref(self, raw)

        refs = {}
        for ref in self.api.yield_from_cursor(query, f):
            refs[ref.name] = ref
        return refs

    def commit(self, *ids):
        query = """{
            user(username: "%s") {
                repository(name: "%s") {
                    objects(ids: [%s]) {
                        id
                        ... on Commit {
                            message
                            author { name, email, time }
                            committer { name, email, time }
                        }
                    }
                }
            }
        }""" % (self.owner.username, self.name, ", ".join([f'"{i}"' for i in ids]))

        data = self.api.graphql(query)
        cs = []
        for raw in data["user"]["repository"]["objects"]:
            cs.append(Commit(self, raw))
        return cs[0] if len(ids) == 1 else cs

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
                            author { name, email, time }
                            committer { name, email, time }
                        }
                    }
                }
            }
        }""" % (self.repo.owner.username, self.repo.name, self.target)

        def f(data):
            repo = data["user"]["repository"]
            if repo is None:
                return
            for raw in repo["log"]["results"]:
                yield Commit(self.repo, raw)

        yield from self.api.yield_from_cursor(query, f)

class Commit:
    def __init__(self, repo, raw):
        self.api = repo.api
        self.repo = repo

        self.id = raw["id"]
        self.message = raw["message"]
        self.author = Signature(raw["author"])
        self.committer = Signature(raw["committer"])

        lines = self.message.splitlines()
        if lines:
            self.title = lines[0]
        else:
            self.title = None

    def __str__(self):
        return self.id

class Signature:
    def __init__(self, raw):
        self.name = raw["name"]
        self.email = raw["email"]
        self.time = datetime.datetime.fromisoformat(raw["time"])

class User:
    def __init__(self, api, raw):
        self.username = raw["username"]
        self.canonicalName = raw["canonicalName"]
        self.email = raw["email"]

    def __str__(self):
        return self.username
