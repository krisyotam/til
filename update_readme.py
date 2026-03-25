#!/usr/bin/env python3
"""Rebuild README.md index from topic directories."""

import os
import re
from pathlib import Path

ROOT = Path(__file__).parent.resolve()
INDEX_RE = re.compile(r"<!-- index starts -->.*<!-- index ends -->", re.DOTALL)
COUNT_RE = re.compile(r"<!-- count starts -->\d+<!-- count ends -->")

def extract_frontmatter(filepath):
    text = filepath.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return {}, text
    end = text.index("---", 3)
    fm_block = text[3:end].strip()
    meta = {}
    for line in fm_block.split("\n"):
        if ":" in line and not line.startswith("  "):
            key, val = line.split(":", 1)
            meta[key.strip()] = val.strip().strip('"')
    return meta, text[end + 3:].strip()

def build_index():
    by_topic = {}
    total = 0
    for topic_dir in sorted(ROOT.iterdir()):
        if not topic_dir.is_dir() or topic_dir.name.startswith("."):
            continue
        entries = []
        for md in sorted(topic_dir.glob("*.md")):
            meta, _ = extract_frontmatter(md)
            title = meta.get("title", md.stem.replace("-", " ").title())
            date = meta.get("date", "")
            entries.append((title, f"{topic_dir.name}/{md.name}", date))
            total += 1
        if entries:
            by_topic[topic_dir.name] = entries

    lines = ["<!-- index starts -->"]
    for topic in sorted(by_topic):
        lines.append(f"## {topic}\n")
        for title, path, date in sorted(by_topic[topic], key=lambda x: x[2], reverse=True):
            url = f"https://github.com/krisyotam/til/blob/main/{path}"
            lines.append(f"* [{title}]({url}) - {date}")
        lines.append("")
    lines.append("<!-- index ends -->")
    return "\n".join(lines), total

if __name__ == "__main__":
    index_text, total = build_index()
    readme = ROOT / "README.md"
    content = readme.read_text(encoding="utf-8")
    content = INDEX_RE.sub(index_text, content)
    content = COUNT_RE.sub(f"<!-- count starts -->{total}<!-- count ends -->", content)
    readme.write_text(content, encoding="utf-8")
    print(f"Updated README.md with {total} TILs")
