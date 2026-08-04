#!/usr/bin/env python3
"""SessionStart hook for /nick:retro.

Two jobs, both cheap and both silent when there is nothing to say:
  1. Inject the global learned conventions retro has accepted, capped hard.
  2. Nag when the next retro is due.

Never fails a session: every path exits 0 with valid JSON.
"""

from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

RETRO_DIR = Path.home() / ".claude" / "retro"
STATE = RETRO_DIR / "state.json"
LEARNED = RETRO_DIR / "learned"
MAX_CHARS = 2400


def emit(context: str) -> None:
    if context.strip():
        print(
            json.dumps(
                {
                    "hookSpecificOutput": {
                        "hookEventName": "SessionStart",
                        "additionalContext": context.strip(),
                    }
                }
            )
        )
    else:
        print(json.dumps({"continue": True, "suppressOutput": True}))
    sys.exit(0)


def read_state() -> dict:
    try:
        return json.loads(STATE.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {}


def learned_block() -> str:
    if not LEARNED.is_dir():
        return ""
    entries: list[tuple[float, str]] = []
    for path in LEARNED.glob("*.md"):
        try:
            raw = path.read_text(encoding="utf-8").strip()
        except OSError:
            continue
        if not raw:
            continue
        # Frontmatter carries "confidence:" and "rule:"; body is the rule text.
        confidence = 0.5
        body = raw
        if raw.startswith("---"):
            _, _, rest = raw.partition("---")
            fm, _, body = rest.partition("---")
            for line in fm.splitlines():
                if line.strip().startswith("confidence:"):
                    try:
                        confidence = float(line.split(":", 1)[1].strip())
                    except ValueError:
                        pass
        body = body.strip()
        if body:
            entries.append((confidence, body))

    if not entries:
        return ""

    entries.sort(key=lambda e: -e[0])
    lines, used = [], 0
    for _, body in entries:
        chunk = body if body.startswith("-") else f"- {body}"
        chunk = " ".join(chunk.split())
        if used + len(chunk) + 1 > MAX_CHARS:
            break
        lines.append(chunk)
        used += len(chunk) + 1
    if not lines:
        return ""
    return "[LEARNED CONVENTIONS — accepted via /nick:retro]\n" + "\n".join(lines)


def due_block(state: dict) -> str:
    last = state.get("lastSyncAt")
    cadence = state.get("cadenceDays", 7)
    if not last:
        return ""
    try:
        then = datetime.fromisoformat(str(last).replace("Z", "+00:00"))
    except ValueError:
        return ""
    days = (datetime.now(timezone.utc) - then).days
    if days < cadence:
        return ""
    return (
        f"[RETRO DUE] Last /nick:retro sync was {days} days ago "
        f"(cadence {cadence}d). Mention this once, briefly, if the moment fits — "
        "do not interrupt the user's task to raise it."
    )


def main() -> None:
    try:
        state = read_state()
        parts = [b for b in (learned_block(), due_block(state)) if b]
        emit("\n\n".join(parts))
    except Exception:  # a hook must never break a session
        print(json.dumps({"continue": True, "suppressOutput": True}))
        sys.exit(0)


if __name__ == "__main__":
    main()
