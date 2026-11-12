#!/usr/bin/env python3
"""SessionStart hook for /nick:retro.

Three jobs, all cheap and all silent when there is nothing to say:
  1. Inject the global learned conventions retro has accepted, capped hard.
  2. In an Ashby checkout that is not the main one (Conductor workspace, linked
     worktree), inject the main checkout's Collaboration Preferences: those
     project dirs have no memory of their own, so the rules never load there.
  3. Nag when the next retro is due.

Never fails a session: every path exits 0 with valid JSON.
"""

from __future__ import annotations

import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

RETRO_DIR = Path.home() / ".claude" / "retro"
STATE = RETRO_DIR / "state.json"
LEARNED = RETRO_DIR / "learned"
MAX_CHARS = 3800

ASHBY_MAIN = Path("/Users/nickhwang/dev/ashby/Ashby")
ASHBY_MEMORY = Path.home() / ".claude" / "projects" / "-Users-nickhwang-dev-ashby-Ashby" / "memory"
PREFS_HEADING = "## Collaboration Preferences"
PREFS_MAX_CHARS = 3600


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


def hook_cwd() -> Path:
    """The session's cwd, from the hook's stdin JSON; falls back to the process cwd."""
    try:
        if not sys.stdin.isatty():
            data = json.loads(sys.stdin.read() or "{}")
            if data.get("cwd"):
                return Path(data["cwd"])
    except (OSError, ValueError):
        pass
    return Path.cwd()


def project_prefs_block(cwd: Path) -> str:
    """Ashby's Collaboration Preferences for an Ashby checkout whose project dir loads no memory."""
    try:
        if cwd.resolve() == ASHBY_MAIN.resolve():
            return ""
        remote = subprocess.run(
            ["git", "-C", str(cwd), "remote", "get-url", "origin"],
            capture_output=True, text=True, timeout=3,
        ).stdout.strip().lower()
    except (OSError, subprocess.SubprocessError):
        return ""
    if not remote.rstrip("/").removesuffix(".git").endswith("ashbyhq/ashby"):
        return ""
    try:
        text = (ASHBY_MEMORY / "MEMORY.md").read_text(encoding="utf-8")
    except OSError:
        return ""
    if PREFS_HEADING not in text:
        return ""
    section = text.split(PREFS_HEADING, 1)[1].split("\n## ", 1)[0].strip()
    if len(section) > PREFS_MAX_CHARS:
        section = section[:PREFS_MAX_CHARS].rsplit("\n", 1)[0]
    return (
        "[ASHBY COLLABORATION PREFERENCES — from the main checkout's memory; this checkout's "
        f"project dir loads none. Entries live in {ASHBY_MEMORY}/]\n" + section
    )


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
        cwd = hook_cwd()
        parts = [b for b in (learned_block(), project_prefs_block(cwd), due_block(state)) if b]
        emit("\n\n".join(parts))
    except Exception:  # a hook must never break a session
        print(json.dumps({"continue": True, "suppressOutput": True}))
        sys.exit(0)


if __name__ == "__main__":
    main()
