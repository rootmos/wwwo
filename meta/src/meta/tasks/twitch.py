import requests
import os
import stat
import re
import json

helix_url = "https://api.twitch.tv/helix"
oauth2_url = "https://id.twitch.tv/oauth2"

client_id = "dqfe0to2kp1pj0yvs3rpvuupdn1u6d"
with open(os.path.expanduser("~/.twitch.client-secret"), "r") as f:
    client_secret = f.read().split('\n')[0]

token_path = os.path.expanduser("~/.twitch.token")

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

def new_token():
    params = {
        "client_id": client_id,
        "client_secret": client_secret,
        "grant_type": "client_credentials",
        "scope": "",
    }
    r = requests.post(oauth2_url + "/token", params=params)
    r.raise_for_status()
    return r.json()["access_token"]

def validate_token(t):
    r = requests.get(oauth2_url + "/validate", headers={ "Authorization": f"OAuth {t}" })
    if r.status_code == 401:
        return False
    r.raise_for_status()
    return True

def get_token():
    t = None

    if os.path.exists(token_path):
        with open(token_path, "r") as f:
            t = f.read()

    if t is not None:
        if not validate_token(t):
            t = None

    if t is None:
        t = new_token()
        with open(token_path, "w") as f:
            f.write(t)
        os.chmod(token_path, 0o600)

    return t

def vods(user_id, token=None, typ=None):
    token = token or get_token()
    h = {
        "Client-ID": client_id,
        "Authorization": f"Bearer {token}",
    }
    p = { "user_id": user_id }
    vs = []

    while True:
        r = requests.get(helix_url + "/videos", params=p, headers=h)
        r.raise_for_status()
        j = r.json()
        for i in j["data"]:
            if typ is not None:
                if typ != i["type"]:
                    break

            vs.append({
                "video_id": i["id"],
                "title": i["title"],
                "url": i["url"],
                "duration": float(parse_duration(i["duration"])),
                "date": i["published_at"],
            })

        if "cursor" not in j["pagination"]: break
        p["after"] = j["pagination"]["cursor"]

    return vs

def main():
    vs = vods(64348860, typ="highlight")
    print(json.dumps(vs))
