"""Loopback-only static server for the leaderboard kit: Studio's installer fetches work/*.mesh.json and
metadata.json from here. Read-only; binds 127.0.0.1:8803."""
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
ROOT = Path(__file__).resolve().parent


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=str(ROOT), **k)

    def log_message(self, *a):
        pass


ThreadingHTTPServer(('127.0.0.1', 8803), Handler).serve_forever()
