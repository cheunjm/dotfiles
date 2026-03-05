#!/usr/bin/env python3
"""Get GitHub App installation token for arami-openclaw-bot."""
import jwt
import time
import urllib.request
import json
import sys

APP_ID = "3012876"
INSTALLATION_ID = 114152195
PEM_PATH = "/Users/jaemincheun/.config/arami/arami-openclaw-bot.pem"

try:
    with open(PEM_PATH) as f:
        private_key = f.read()

    payload = {
        "iat": int(time.time()) - 60,
        "exp": int(time.time()) + 540,
        "iss": APP_ID,
    }
    token = jwt.encode(payload, private_key, algorithm="RS256")

    req = urllib.request.Request(
        f"https://api.github.com/app/installations/{INSTALLATION_ID}/access_tokens",
        data=b"{}",
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req) as r:
        print(json.loads(r.read())["token"])
except Exception as e:
    print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)
