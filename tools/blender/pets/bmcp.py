"""Tiny client for the MCP for Blender add-on socket (127.0.0.1:9876).

It talks to the same add-on bridge the Blender MCP server (mcp-for-blender) uses, so these scripts run with or
without the MCP server. `code` joins the files in order and prepends REPO = <repository root>, ARGS = the
`key=value` pairs after `--`, and a boot block that puts this folder on sys.path and drops cached `kit`, `heroes`,
`zones` and `v3` modules (so every run imports the current source).
Usage:
  python -I bmcp.py ping
  python -I bmcp.py code build.py -- what=zone1          # runs the files inside the live Blender GUI
  python -I bmcp.py raw '{"type": "...", "params": {...}}'
"""
import os

import json
import socket
import sys


BOOT = """import sys
_kit = REPO + "/tools/blender/pets"
if _kit not in sys.path:
    sys.path.insert(0, _kit)
for _m in [m for m in sys.modules if m.split(".")[0] in ("kit", "heroes", "zones", "v3")]:
    del sys.modules[_m]
"""


def send(cmd: dict, timeout: float = 600.0) -> dict:
    with socket.create_connection(("127.0.0.1", 9876), timeout=timeout) as s:
        s.sendall(json.dumps(cmd).encode("utf-8"))
        buf = b""
        while True:
            chunk = s.recv(65536)
            if not chunk:
                break
            buf += chunk
            try:
                return json.loads(buf.decode("utf-8"))
            except ValueError:
                continue
    return json.loads(buf.decode("utf-8"))


def main() -> None:
    mode = sys.argv[1]
    if mode == "ping":
        cmd = {"type": "ping", "params": {}}
    elif mode == "code":  # several files are joined in order
        root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
        files, args = sys.argv[2:], {}
        if "--" in files:
            k = files.index("--")
            files, args = files[:k], dict(a.split("=", 1) for a in files[k + 1 :])
        code = "REPO = %r\nARGS = %r\n" % (root.replace("\\", "/"), args) + BOOT
        for path in files:
            with open(path, encoding="utf-8") as f:
                code += f.read() + "\n"
        cmd = {"type": "execute_code", "params": {"code": code}}
    else:
        cmd = json.loads(sys.argv[2])
    res = send(cmd)
    if res.get("status") == "success" and isinstance(res.get("result"), dict) and "result" in res["result"]:
        print(res["result"]["result"])
    else:
        print(json.dumps(res, indent=1)[:20000])


if __name__ == "__main__":
    main()
