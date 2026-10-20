"""Uploads model files (FBX / GLB) or images (PNG) to Roblox with Open Cloud and prints the asset ids.

The API key comes from the ROBLOX_API_KEY user environment variable (read from the registry, so a key set after this
shell started is found too). It is never printed. Usage:
  python tools/world/upload.py --creator <userId> --type Model file1.fbx [file2.fbx ...] [--out ids.json]
  python tools/world/upload.py --creator <userId> --type Decal sprite.png
Results are merged into --out (JSON: {file stem: asset id}); files already listed there are skipped unless --force.
"""

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
import uuid

API = "https://apis.roblox.com/assets/v1"
TYPES = {".fbx": "model/fbx", ".glb": "model/gltf-binary", ".gltf": "model/gltf+json", ".png": "image/png"}


def api_key() -> str:
    key = None
    if sys.platform == "win32":
        import winreg

        try:
            with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment") as k:
                key = winreg.QueryValueEx(k, "ROBLOX_API_KEY")[0]
        except OSError:
            key = None
    key = key or os.environ.get("ROBLOX_API_KEY")
    if not key:
        sys.exit("ROBLOX_API_KEY is not set")
    return key.strip()


def request(method, url, key, body=None, ctype=None):
    req = urllib.request.Request(url, data=body, method=method)
    req.add_header("x-api-key", key)
    if ctype:
        req.add_header("Content-Type", ctype)
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return r.status, json.loads(r.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        return e.code, {"error": e.read().decode(errors="replace")[:500]}


def upload(path, asset_type, creator, key, display=None):
    name = display or os.path.splitext(os.path.basename(path))[0]
    meta = {
        "assetType": asset_type,
        "displayName": name[:50],
        "description": "Kick the Egg! world asset",
        "creationContext": {"creator": {"userId": str(creator)}},
    }
    b = uuid.uuid4().hex
    with open(path, "rb") as f:
        data = f.read()
    ctype = TYPES[os.path.splitext(path)[1].lower()]
    body = (
        f'--{b}\r\nContent-Disposition: form-data; name="request"\r\n\r\n{json.dumps(meta)}\r\n'
        f'--{b}\r\nContent-Disposition: form-data; name="fileContent"; filename="{os.path.basename(path)}"\r\n'
        f"Content-Type: {ctype}\r\n\r\n"
    ).encode() + data + f"\r\n--{b}--\r\n".encode()
    status, res = request("POST", f"{API}/assets", key, body, f"multipart/form-data; boundary={b}")
    if status >= 300:
        return None, f"HTTP {status} {res.get('error', res)}"
    op = res.get("path") or ""
    for _ in range(90):
        if res.get("done"):
            break
        time.sleep(2)
        status, res = request("GET", f"{API}/{op}", key)
        if status >= 300:
            return None, f"poll HTTP {status} {res.get('error', res)}"
    if not res.get("done"):
        return None, "timed out"
    if "error" in res:
        return None, json.dumps(res["error"])
    return res["response"]["assetId"], None


def main():
    p = argparse.ArgumentParser()
    p.add_argument("files", nargs="+")
    p.add_argument("--creator", required=True)
    p.add_argument("--type", default="Model")
    p.add_argument("--out")
    p.add_argument("--force", action="store_true")
    args = p.parse_args()
    key = api_key()
    ids = {}
    if args.out and os.path.exists(args.out):
        with open(args.out, encoding="utf-8") as f:
            ids = json.load(f)
    failed = 0
    for path in args.files:
        stem = os.path.splitext(os.path.basename(path))[0]
        if stem in ids and not args.force:
            print(f"skip {stem} = {ids[stem]}")
            continue
        asset, err = upload(path, args.type, args.creator, key)
        if err:
            failed += 1
            print(f"FAIL {stem}: {err}")
            continue
        ids[stem] = asset
        print(f"OK {stem} = {asset}")
        if args.out:
            with open(args.out, "w", encoding="utf-8") as f:
                json.dump(ids, f, indent=1, sort_keys=True)
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
