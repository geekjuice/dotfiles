#!/usr/bin/env python3
"""Extract learning signal from Claude Code session transcripts.

Reads ~/.claude/projects/**/*.jsonl, pulls out real typed user prompts paired
with what Claude did immediately before them, and writes a compact corpus the
/nick:retro lens agents can analyze without touching the raw transcripts.

Outputs into --out:
  pairs.jsonl   one record per real user prompt, newest last
  metrics.json  aggregate workflow stats over the same window
  manifest.json window, file/session counts, generated-at
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path

# ---------------------------------------------------------------- filters

# A "real prompt" is type=user, not a sidechain, userType=external, and string
# content. Array content on a user turn is a tool_result or a skill injection.
NOISE_PREFIXES = (
    "<",
    "Caveat:",
    "Another Claude session sent a message:",
    "Review this change for security vulnerabilities.",
    "Base directory for this skill:",
    "[Request interrupted",
    "API Error",
    "Error: ",
    # Machine-authored turns that arrive on the user channel. Without these the
    # corpus reads as though Nick said them, and they skew every heuristic flag.
    "Stop hook feedback:",
    "This session is being continued from a previous conversation",
    "PreToolUse:",
    "PostToolUse:",
    "[MAGIC KEYWORD",
)

SYSTEM_REMINDER_RE = re.compile(r"<system-reminder>.*?</system-reminder>", re.DOTALL)
COMMAND_WRAPPER_RE = re.compile(r"<command-(name|message|args)>.*?</command-\1>", re.DOTALL)
LOCAL_STDOUT_RE = re.compile(r"<local-command-stdout>.*?</local-command-stdout>", re.DOTALL)
SLASH_RE = re.compile(r"^(/[a-zA-Z0-9_:-]+)")

# Slash invocations reach the transcript wrapped, not as plain "/nick:review".
COMMAND_NAME_RE = re.compile(r"<command-name>\s*([^<\s]+)\s*</command-name>")
COMMAND_ARGS_RE = re.compile(r"<command-args>(.*?)</command-args>", re.DOTALL)

# Cheap heuristics. These do not decide anything — they give the lens agents a
# starting point so they are not reading 300 prompts cold.
FLAG_PATTERNS = {
    "negation": re.compile(
        r"^\s*(no\b|nope|nah|wrong|stop\b|don'?t\b|revert|undo|that'?s not|not (that|quite|what))",
        re.I,
    ),
    "repeat_ask": re.compile(
        r"\b(i (told|said|asked)|like i said|as i said|again\b|still\b|why did you|"
        r"you keep|every time|once more|as mentioned)",
        re.I,
    ),
    "nit": re.compile(r"\b(nit|nits|nitpick|small thing|minor|one more thing|few things)\b", re.I),
    "praise": re.compile(
        r"\b(nice|perfect|great|lgtm|ship it|exactly|love it|thanks|looks good|works)\b", re.I
    ),
    "preference": re.compile(
        r"\b(always|never|from now on|going forward|prefer|instead of|by default|"
        r"make sure to|remember to|in the future)\b",
        re.I,
    ),
    "scope_change": re.compile(
        r"\b(actually|instead|scratch that|change of plan|on second thought|let'?s also|"
        r"can we also|one more)\b",
        re.I,
    ),
}

# Test/typecheck commands with no path argument = whole-repo run. CLAUDE.md says
# scope these to changed files, so each hit is a minutes-long avoidable wait.
BROAD_TEST_RE = re.compile(
    r"(?:^|&&|;|\|)\s*(?:cd\s+\S+\s*&&\s*)?"
    r"(?:(?:pnpm|npm|yarn|bun)\s+(?:run\s+)?(?:test|typecheck)"
    r"|(?:npx\s+)?(?:vitest|jest)(?:\s+run)?"
    r"|(?:npx\s+)?tsc\s+--noEmit)"
    r"\s*(?:$|&&|;|\|)",
    re.I | re.M,
)


def parse_ts(raw: str | None) -> datetime | None:
    """Always returns an aware datetime. A bare --since 2026-07-24 is read as UTC."""
    if not raw:
        return None
    try:
        parsed = datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        return None
    return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)


def clean_prompt(text: str) -> str:
    text = SYSTEM_REMINDER_RE.sub("", text)
    text = LOCAL_STDOUT_RE.sub("", text)
    text = COMMAND_WRAPPER_RE.sub("", text)
    return text.strip()


def is_noise(text: str) -> bool:
    if not text or len(text) < 2:
        return True
    return text.startswith(NOISE_PREFIXES)


def truncate(text: str, limit: int) -> tuple[str, bool]:
    if len(text) <= limit:
        return text, False
    head = limit * 2 // 3
    tail = limit - head
    return f"{text[:head]}\n…[{len(text) - limit} chars elided]…\n{text[-tail:]}", True


def assistant_text(content) -> str:
    if isinstance(content, str):
        return content
    if not isinstance(content, list):
        return ""
    return "\n".join(b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == "text").strip()


def project_name(cwd: str | None) -> str:
    if not cwd:
        return "unknown"
    return Path(cwd).name or "unknown"


# ---------------------------------------------------------------- extraction


def scan_file(path: Path, since: datetime, until: datetime | None, opts) -> tuple[list[dict], dict]:
    """Single forward pass over one transcript. Returns (pairs, per-file metrics)."""
    pairs: list[dict] = []
    m = {
        "tool_calls": Counter(),
        "broad_test_runs": 0,
        "interruptions": 0,
        "agent_spawns": 0,
        "sessions": set(),
        "assistant_turns": 0,
    }

    # Rolling state between user prompts.
    last_assistant = ""
    tools_since_prompt: Counter = Counter()
    interrupted_since_prompt = False
    turn_index = 0
    session_id = path.stem

    try:
        fh = path.open("r", encoding="utf-8", errors="replace")
    except OSError:
        return pairs, m

    with fh:
        for line in fh:
            # Cheap prefilter: most lines are attachments / file snapshots.
            if '"type":"user"' not in line and '"type":"assistant"' not in line:
                continue
            try:
                rec = json.loads(line)
            except (json.JSONDecodeError, ValueError):
                continue

            rtype = rec.get("type")
            msg = rec.get("message") or {}

            if rtype == "assistant":
                m["assistant_turns"] += 1
                content = msg.get("content")
                text = assistant_text(content)
                if text:
                    last_assistant = text
                if isinstance(content, list):
                    for block in content:
                        if not isinstance(block, dict) or block.get("type") != "tool_use":
                            continue
                        name = block.get("name", "?")
                        m["tool_calls"][name] += 1
                        tools_since_prompt[name] += 1
                        if name == "Agent":
                            m["agent_spawns"] += 1
                        if name == "Bash":
                            cmd = (block.get("input") or {}).get("command", "")
                            if isinstance(cmd, str) and BROAD_TEST_RE.search(cmd):
                                m["broad_test_runs"] += 1
                continue

            # rtype == "user"
            content = msg.get("content")
            if isinstance(content, list):
                # Interruptions land here as a plain text block, not a tool_result.
                for block in content:
                    if not isinstance(block, dict):
                        continue
                    if block.get("type") == "text":
                        blob = block.get("text") or ""
                    elif block.get("type") == "tool_result":
                        c = block.get("content")
                        blob = c if isinstance(c, str) else json.dumps(c)[:400]
                    else:
                        continue
                    if "Request interrupted" in blob:
                        m["interruptions"] += 1
                        interrupted_since_prompt = True
                continue

            if not isinstance(content, str):
                continue
            if rec.get("isSidechain") or rec.get("userType") != "external":
                continue

            ts = parse_ts(rec.get("timestamp"))
            if ts is None or ts < since or (until and ts > until):
                # Still reset rolling state so context never crosses the window edge.
                last_assistant, tools_since_prompt, interrupted_since_prompt = "", Counter(), False
                continue

            if "Request interrupted" in content:
                m["interruptions"] += 1
                interrupted_since_prompt = True

            # A wrapped slash invocation is signal (which skills get reached for,
            # and what the next prompt says about how they went), not noise.
            cmd = COMMAND_NAME_RE.search(content)
            if cmd:
                args_match = COMMAND_ARGS_RE.search(content)
                kind = "slash"
                command = cmd.group(1)
                text = clean_prompt(args_match.group(1) if args_match else "")
            else:
                kind = "prompt"
                command = None
                text = clean_prompt(content)
                if is_noise(text):
                    continue

            sid = rec.get("sessionId") or session_id
            m["sessions"].add(sid)
            turn_index += 1

            prompt, prompt_trunc = truncate(text, opts.max_prompt_chars)
            prior, _ = truncate(last_assistant, opts.max_context_chars)
            slash = SLASH_RE.match(text) if kind == "prompt" else None

            flags = [name for name, pat in FLAG_PATTERNS.items() if pat.search(text[:600])]

            pairs.append(
                {
                    "uuid": rec.get("uuid"),
                    "session": sid,
                    "ts": rec.get("timestamp"),
                    "project": project_name(rec.get("cwd")),
                    "cwd": rec.get("cwd"),
                    "branch": rec.get("gitBranch"),
                    "turn": turn_index,
                    "kind": kind,
                    "slash": command or (slash.group(1) if slash else None),
                    "flags": flags,
                    "prompt": prompt,
                    "prompt_truncated": prompt_trunc,
                    "prior_assistant": prior,
                    "prior_tools": dict(tools_since_prompt.most_common(8)),
                    "prior_interrupted": interrupted_since_prompt,
                }
            )

            last_assistant, tools_since_prompt, interrupted_since_prompt = "", Counter(), False

    return pairs, m


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--since", help="ISO-8601 lower bound. Default: 14 days ago.")
    ap.add_argument("--until", help="ISO-8601 upper bound. Default: now.")
    ap.add_argument("--days", type=int, help="Shorthand for --since N days ago.")
    ap.add_argument("--out", required=True, help="Output directory (created if absent).")
    ap.add_argument("--projects-dir", default=str(Path.home() / ".claude" / "projects"))
    ap.add_argument("--max-prompt-chars", type=int, default=4000)
    ap.add_argument("--max-context-chars", type=int, default=1200)
    ap.add_argument("--exclude-project", action="append", default=[])
    ap.add_argument("--only-project", action="append", default=[])
    opts = ap.parse_args()

    now = datetime.now(timezone.utc)
    if opts.since:
        since = parse_ts(opts.since)
        if since is None:
            print(f"bad --since: {opts.since}", file=sys.stderr)
            return 2
    else:
        since = now - timedelta(days=opts.days or 14)
    until = parse_ts(opts.until) if opts.until else None

    root = Path(opts.projects_dir).expanduser()
    if not root.is_dir():
        print(f"no projects dir at {root}", file=sys.stderr)
        return 2

    # mtime prefilter with 3 days of slack: a file touched today can hold
    # messages from well before the window, and vice versa.
    cutoff = (since - timedelta(days=3)).timestamp()
    files = [p for p in root.rglob("*.jsonl") if p.stat().st_mtime >= cutoff]

    all_pairs: list[dict] = []
    agg = {
        "tool_calls": Counter(),
        "broad_test_runs": 0,
        "interruptions": 0,
        "agent_spawns": 0,
        "assistant_turns": 0,
    }
    sessions: set[str] = set()

    for path in files:
        pairs, m = scan_file(path, since, until, opts)
        all_pairs.extend(pairs)
        agg["tool_calls"].update(m["tool_calls"])
        for key in ("broad_test_runs", "interruptions", "agent_spawns", "assistant_turns"):
            agg[key] += m[key]
        sessions |= m["sessions"]

    # Transcripts fork on resume, so the same prompt can appear in two files.
    seen: set = set()
    deduped = []
    for p in sorted(all_pairs, key=lambda r: (r["ts"] or "", r["session"])):
        key = p["uuid"] or (p["session"], p["ts"], p["prompt"][:120])
        if key in seen:
            continue
        seen.add(key)
        deduped.append(p)

    out = Path(opts.out).expanduser()
    out.mkdir(parents=True, exist_ok=True)

    keep = []
    for p in deduped:
        if opts.only_project and p["project"] not in opts.only_project:
            continue
        if p["project"] in opts.exclude_project:
            continue
        keep.append(p)

    with (out / "pairs.jsonl").open("w", encoding="utf-8") as fh:
        for p in keep:
            fh.write(json.dumps(p, ensure_ascii=False) + "\n")

    by_project = Counter(p["project"] for p in keep)
    by_day = Counter((p["ts"] or "")[:10] for p in keep)
    by_session = Counter(p["session"] for p in keep)
    slashes = Counter(p["slash"] for p in keep if p["slash"])
    flags = Counter(f for p in keep for f in p["flags"])
    rounds = sorted(by_session.values(), reverse=True)

    metrics = {
        "window": {"since": since.isoformat(), "until": (until or now).isoformat()},
        "prompts": sum(1 for p in keep if p["kind"] == "prompt"),
        "slash_invocations": sum(1 for p in keep if p["kind"] == "slash"),
        "records": len(keep),
        "sessions_with_prompts": len(by_session),
        "sessions_seen": len(sessions),
        "transcripts_scanned": len(files),
        "assistant_turns": agg["assistant_turns"],
        "interruptions": agg["interruptions"],
        "agent_spawns": agg["agent_spawns"],
        "broad_test_runs": agg["broad_test_runs"],
        "tool_calls": dict(agg["tool_calls"].most_common(25)),
        "by_project": dict(by_project.most_common()),
        "by_day": dict(sorted(by_day.items())),
        "slash_commands": dict(slashes.most_common(25)),
        "heuristic_flags": dict(flags.most_common()),
        "rounds_per_session": {
            "max": rounds[0] if rounds else 0,
            "median": rounds[len(rounds) // 2] if rounds else 0,
            "long_sessions": [
                {"session": s, "prompts": n, "project": next(p["project"] for p in keep if p["session"] == s)}
                for s, n in by_session.most_common(10)
            ],
        },
    }
    (out / "metrics.json").write_text(json.dumps(metrics, indent=2), encoding="utf-8")
    (out / "manifest.json").write_text(
        json.dumps(
            {
                "generated_at": now.isoformat(),
                "since": since.isoformat(),
                "until": (until or now).isoformat(),
                "pairs_file": str(out / "pairs.jsonl"),
                "pairs": len(keep),
                "projects_dir": str(root),
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    print(
        f"{len(keep)} prompts across {len(by_session)} sessions "
        f"({len(files)} transcripts scanned) -> {out}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
