import argparse
import json
import os
import re
import requests
import base64

from .common import fetch_secret, output

def parse_duration(string):
    p = re.compile("([0-9]+)([dDhHmMsS])")
    secs = 0
    for m in p.finditer(string):
        n = int(m.group(1))
        t = m.group(2)
        if t == "s" or t == "S":
            secs += n
        elif t == "m" or t == "M":
            secs += n * 60
        elif t == "h" or t == "H":
            secs += n * 60 * 60
        elif t == "d" or t == "D":
            secs += n * 60 * 60 * 24
    return secs

def download_thumbnail(url_template, width, height):
    url = url_template.replace("%{width}", str(width)).replace("%{height}", str(height))
    r = requests.get(url)
    return str(base64.b64encode(r.content), "UTF-8")

class Crawler:
    helix_url = "https://api.twitch.tv/helix"
    oauth2_url = "https://id.twitch.tv/oauth2"

    def __init__(self, thumbnail_width, thumbnail_height):
        self.client_id = os.environ["TWITCH_CLIENT_ID"]
        self.client_secret = fetch_secret(os.environ["TWITCH_CLIENT_SECRET_ARN"])

        self._token = None
        self._user_id = None

        self.thumbnail_width = thumbnail_width
        self.thumbnail_height = thumbnail_height

    @property
    def token(self):
        if self._token is None:
            params = {
                "client_id": self.client_id,
                "client_secret": self.client_secret,
                "grant_type": "client_credentials",
                "scope": "",
            }
            r = requests.post(Crawler.oauth2_url + "/token", params=params)
            r.raise_for_status()
            self._token = r.json()["access_token"]
        return self._token

    def vods(self, user_id, typ=None):
        h = {
            "Client-ID": self.client_id,
            "Authorization": f"Bearer {self.token}",
        }
        p = { "user_id": user_id }
        vs = []

        while True:
            r = requests.get(Crawler.helix_url + "/videos", params=p, headers=h)
            r.raise_for_status()
            j = r.json()
            for i in j["data"]:
                if typ is not None:
                    if typ != i["type"]:
                        break

                yield {
                    "video_id": i["id"],
                    "title": i["title"],
                    "url": i["url"],
                    "duration": float(parse_duration(i["duration"])),
                    "date": i["published_at"],
                    "thumbnail": download_thumbnail(i["thumbnail_url"], self.thumbnail_width, self.thumbnail_height),
                }

            if "cursor" not in j["pagination"]: break
            p["after"] = j["pagination"]["cursor"]

        return vs

    def user_id(self, login):
        h = {
            "Client-ID": self.client_id,
            "Authorization": f"Bearer {self.token}",
        }
        p = { "login": [login] }
        r = requests.get(Crawler.helix_url + "/users", params=p, headers=h)
        r.raise_for_status()
        [u] = r.json()["data"]
        return u["id"]

def parse_args():
    parser = argparse.ArgumentParser(description="Fetch metadata about Twitch vods")

    parser.add_argument("-o", "--output")

    parser.add_argument("--type", default="highlight")

    parser.add_argument("--thumbnail-width", type=int, default=320)
    parser.add_argument("--thumbnail-height", type=int, default=180)

    parser.add_argument("login")

    return parser.parse_args()

def main():
    args = parse_args()

    c = Crawler(thumbnail_width=args.thumbnail_width, thumbnail_height=args.thumbnail_height)

    user_id = c.user_id(args.login)
    vs = list(c.vods(user_id, typ=args.type))
    with output(args.output) as f:
        f.write(json.dumps(vs))
