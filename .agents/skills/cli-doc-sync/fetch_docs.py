#!/usr/bin/env python3
"""
fetch_docs.py — 從官方文件 URL 抓取 CLI 參考內容，轉為 Markdown 後以 JSON 輸出。

Usage:
    python fetch_docs.py claude-code          # 抓取指定目標的所有來源
    python fetch_docs.py github-copilot       # 同上
    python fetch_docs.py codex-cli            # 同上
    python fetch_docs.py --url URL            # 抓取單一 URL
    python fetch_docs.py --list               # 列出可用目標

Output (stdout):
    JSON object with fetched markdown content per source URL.

Dependencies:
    pip install requests markdownify
"""

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

import requests
from markdownify import markdownify as md

TARGETS_FILE = Path(__file__).parent / "targets.json"
REQUEST_TIMEOUT = 30
USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/131.0.0.0 Safari/537.36"
)


def load_targets() -> dict:
    with open(TARGETS_FILE, encoding="utf-8") as f:
        return json.load(f)


def fetch_url(url: str) -> dict:
    """Fetch a URL and convert its HTML to Markdown."""
    try:
        resp = requests.get(
            url,
            timeout=REQUEST_TIMEOUT,
            headers={"User-Agent": USER_AGENT},
        )
        resp.raise_for_status()
        content_md = md(
            resp.text,
            heading_style="ATX",
            bullets="-",
            strip=["script", "style", "nav", "footer", "header"],
        )
        return {"url": url, "content_md": content_md}
    except requests.RequestException as e:
        return {"url": url, "error": str(e), "content_md": None}


def fetch_target(name: str, targets: dict) -> dict:
    """Fetch all sources for a named target."""
    target = targets[name]
    sources = []
    for src in target["sources"]:
        result = fetch_url(src["url"])
        result["label"] = src["label"]
        sources.append(result)
    return {
        "target": name,
        "md_path": target["md_path"],
        "fetched_at": datetime.now(timezone.utc).isoformat(),
        "sources": sources,
    }


def main():
    parser = argparse.ArgumentParser(
        description="Fetch CLI reference docs and output as JSON."
    )
    parser.add_argument(
        "target",
        nargs="?",
        help="Target name (e.g. claude-code, github-copilot, codex-cli)",
    )
    parser.add_argument(
        "--url",
        help="Fetch a single URL directly",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List available targets",
    )
    args = parser.parse_args()

    targets = load_targets()

    if args.list:
        listing = {}
        for name, cfg in targets.items():
            listing[name] = {
                "md_path": cfg["md_path"],
                "sources": [s["url"] for s in cfg["sources"]],
            }
        json.dump(listing, sys.stdout, indent=2, ensure_ascii=False)
        print()
        return

    if args.url:
        result = fetch_url(args.url)
        result["fetched_at"] = datetime.now(timezone.utc).isoformat()
        json.dump(result, sys.stdout, indent=2, ensure_ascii=False)
        print()
        return

    if args.target:
        if args.target not in targets:
            print(
                json.dumps(
                    {"error": f"Unknown target: {args.target}. Use --list to see available targets."},
                    ensure_ascii=False,
                ),
                file=sys.stderr,
            )
            sys.exit(1)
        result = fetch_target(args.target, targets)
        json.dump(result, sys.stdout, indent=2, ensure_ascii=False)
        print()
        return

    parser.print_help()
    sys.exit(1)


if __name__ == "__main__":
    main()
