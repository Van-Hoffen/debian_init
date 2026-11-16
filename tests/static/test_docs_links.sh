#!/usr/bin/env bash
# STAT-004: относительные ссылки в Markdown.
set -euo pipefail
: "${ROOT_DIR:?}" "${TESTS_DIR:?}"
# shellcheck source=lib/assert.sh
. "$TESTS_DIR/lib/assert.sh"

check_links() {
    python3 - "$ROOT_DIR" <<'PY'
import os
import re
import sys

root = sys.argv[1]
bad = []
for dirpath, dirnames, filenames in os.walk(root):
    dirnames[:] = [d for d in dirnames if d not in {".git", "node_modules", "tests", ".artifacts"}]
    for name in filenames:
        if not name.endswith(".md"):
            continue
        path = os.path.join(dirpath, name)
        text = open(path, encoding="utf-8").read()
        for m in re.finditer(r"\]\(([^)\s]+)\)", text):
            target = m.group(1)
            if target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            target = target.split("#", 1)[0]
            if not target:
                continue
            full = os.path.normpath(os.path.join(dirpath, target))
            if not os.path.exists(full):
                bad.append(f"{os.path.relpath(path, root)}: {target}")
if bad:
    print("битые ссылки:")
    print("\n".join(bad))
    sys.exit(1)
PY
}

test_case "относительные ссылки в Markdown" check_links
finish
