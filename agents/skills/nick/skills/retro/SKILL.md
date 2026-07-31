---
user-invocable: true
description: "Weekly retrospective over past Claude Code sessions. Reads how work actually went, extracts what you keep having to repeat, and proposes durable fixes to memory, your nick: skills, or a new skill draft. Every change needs your approval. Flags: `--days N`, `--since <date>`, `--status`, `--dry-run`, `--lens <name>`, `--project <name>`, `--exclude <name>`, `--max N`, `--reset`."
---

# retro

Read the last stretch of sessions, work out what you had to say more than once, and turn that into something durable so you never say it again. Run it weekly.

`$ARGUMENTS` sets the window and the depth. Everything else is fixed: extract deterministically (§3), analyze in parallel lenses (§5), gate hard on evidence (§6), and change nothing without your say-so (§7).

The bar for a lesson is not "this happened." It is **"this happened more than once, and there is a specific edit that would stop it happening again."** Most of what a week of sessions contains is not a lesson. Discarding aggressively is the job, not a failure of it.

---

## 1. Inputs

**Window** (pick one; default is incremental from the last sync):
- *nothing* → since `lastSyncAt` in state. First ever run → last **14 days**.
- `--days N` → last N days.
- `--since <date>` → explicit ISO date or `YYYY-MM-DD`.
- `--reset` → ignore `lastSyncAt`, treat this as a first run (14 days unless combined with `--days`/`--since`).

**Scope:**
- `--project <name>` — only this project (repeatable). Matches the cwd basename, e.g. `Ashby`, `.dotfiles`.
- `--exclude <name>` — drop a project (repeatable).
- `--lens <name>` — run one lens only: `corrections`, `repeats`, `workflow`, `wins`. Repeatable.

**Behavior:**
- `--dry-run` — do the full analysis, print the proposals, apply nothing and write no state.
- `--max N` — cap proposals surfaced for approval (default 12). The rest are held, not dropped: they carry into the next run.
- `--status` — print last sync, days since, run history, live tombstones, and applied-lesson count. Do nothing else. Exit.

Examples:
- `/nick:retro` → incremental run since last sync.
- `/nick:retro --days 30 --lens workflow` → month of workflow-waste analysis only.
- `/nick:retro --dry-run --project Ashby` → see what it would propose for Ashby, change nothing.

---

## 2. State

Everything lives under `~/.claude/retro/`:

| Path | Holds |
|---|---|
| `state.json` | `lastSyncAt`, `cadenceDays`, run history, tombstones, applied ledger |
| `learned/*.md` | Accepted **global** conventions. Injected into every session by the SessionStart hook, capped at ~1800 chars, highest confidence first. |
| `coaching/<date>.md` | Coaching notes on your own prompting. Written, never auto-applied. |
| `runs/<timestamp>/` | That run's `pairs.jsonl`, `metrics.json`, `manifest.json`. Disposable. |

`state.json` shape:

```json
{
  "version": 1,
  "lastSyncAt": "2026-07-31T18:00:00+00:00",
  "cadenceDays": 7,
  "runs": [{"at": "...", "since": "...", "until": "...", "prompts": 268, "proposed": 9, "accepted": 6, "rejected": 3}],
  "tombstones": [{"slug": "...", "claim": "...", "rejectedAt": "...", "sessionsAtRejection": ["uuid"], "newSessionsSince": ["uuid"]}],
  "applied": [{"slug": "...", "claim": "...", "target": "path", "appliedAt": "..."}]
}
```

Create the dir and a `{"version": 1, "cadenceDays": 7}` state on first run. Never hand-edit `runs/`.

---

## 3. Stage 1 — Extract (deterministic, ~3s)

```bash
python3 ~/.claude/skills/nick/skills/retro/scripts/extract.py \
  --out ~/.claude/retro/runs/<UTC-timestamp> \
  [--since <iso> | --days N] [--only-project X] [--exclude-project Y]
```

It sweeps `~/.claude/projects/**/*.jsonl` and writes:

- **`pairs.jsonl`** — one record per real typed prompt or slash invocation, in time order. Fields: `session`, `ts`, `project`, `branch`, `turn`, `kind` (`prompt`|`slash`), `slash`, `flags`, `prompt`, `prior_assistant` (what Claude said right before, truncated), `prior_tools` (tool counts since your last turn), `prior_interrupted`.
- **`metrics.json`** — window, counts, per-project and per-day breakdown, tool totals, `interruptions`, `agent_spawns`, `broad_test_runs`, slash-command frequency, `rounds_per_session` with the longest sessions named.

The script already drops the machine-authored noise that arrives on the user channel: hook feedback, teammate messages, compaction summaries, skill injections, security-review prompts. **Do not re-filter or second-guess it — read what it gives you.**

`flags` are cheap regex hints (`negation`, `repeat_ask`, `nit`, `praise`, `preference`, `scope_change`). They are a starting point for a lens, never evidence on their own. An unflagged prompt can hold the best lesson in the corpus.

If extraction returns fewer than 10 prompts, say so and stop. There is nothing to learn from a quiet week.

---

## 4. Stage 2 — Load what already exists

Before any analysis, read (and pass to every lens):

1. `~/.claude/CLAUDE.md` — the conventions already written down.
2. `~/.claude/retro/learned/*.md` — conventions retro already accepted.
3. `ls ~/.claude/skills/nick/skills/` and the `description:` line of each `SKILL.md`.
4. `state.json` tombstones and applied ledger.

This exists to answer one question per candidate lesson: **is this already written down?**

- **Not written down** → a normal proposal.
- **Written down and you still had to repeat it** → this is the more valuable finding. The rule exists and is not landing. The proposal is to *strengthen, relocate, or sharpen* it (move it from CLAUDE.md into the specific skill that keeps violating it; make a vague rule concrete). Never propose adding a duplicate.

---

## 5. Stage 3 — Fan out by lens

Spawn the lenses **in parallel, one Agent call each, in a single message**. Use `general-purpose`. Each gets: the run dir path, the §4 context, the tombstone list, the §6 evidence bar, and the output schema below.

Tell every lens: *read `pairs.jsonl` yourself with jq and Read — do not ask for it to be pasted. Return raw JSON, no commentary.*

**Lens `corrections`** — where you pushed back. Rework requests, nit lists after delivery, "no", "actually", "that's not what I meant", re-explanations, and anything following `prior_interrupted: true`. For each, read `prior_assistant` to see *what Claude did that earned the correction*. The lesson is the pattern behind the correction, not the correction.

**Lens `repeats`** — the same instruction given across two or more distinct sessions. Frequency, not sentiment. Cluster by meaning rather than wording. Cross-check §4: a repeat of something already documented is a landing failure, not a new rule.

**Lens `workflow`** — how the work went, from `metrics.json` plus the pairs. Rounds-to-completion, sessions that took many turns to land, interruptions, idle-polling ("are you still running?"), whole-repo test/typecheck runs where CLAUDE.md asks for scoped ones, agent spawn counts against work delivered, wrong-directory or wrong-branch work, over- or under-delegation. Name the cost in time or turns.

**Lens `wins`** — what landed first try or drew explicit approval. Look for the shape: which prompt forms, which skills, which approaches. Propose reinforcing them as defaults. Keep this lens short; two or three findings, not ten.

Lens output:

```json
{"lessons": [{
  "slug": "kebab-case-id",
  "claim": "one sentence, imperative, what should change",
  "why": "the pattern behind it, one or two sentences",
  "occurrences": 4,
  "distinct_sessions": 3,
  "evidence": [{"session": "uuid", "ts": "iso", "project": "Ashby", "quote": "verbatim, <200 chars"}],
  "already_documented": "none" | "CLAUDE.md: <quoted rule>" | "learned/<slug>",
  "scope": "global" | "project:<name>" | "skill:<name>",
  "target_kind": "learned" | "project-memory" | "skill-edit" | "new-skill" | "coaching",
  "proposed_change": "the exact text to write, or the exact before/after for a skill edit",
  "confidence": 0.0
}]}
```

---

## 6. Stage 4 — Merge and gate

Do this yourself, in the lead session. It is cheap and it is where quality is won.

**Dedup.** Lenses overlap by design. Merge lessons making the same claim; union their evidence; keep the strongest `proposed_change`.

**Evidence bar.** Drop anything that fails:
- ≥ **2 distinct sessions**, *or* exactly 1 if it is an explicit standing instruction ("always", "never", "from now on", "going forward").
- Every quote real and traceable to a session id. No paraphrase presented as a quote. If a lens returns a quote you cannot find in `pairs.jsonl`, drop the whole lesson and say the lens fabricated it.
- The `proposed_change` is concrete enough to apply without further interpretation. "Be more careful about tests" fails. "In /nick:review, run the failing test before reporting a test-coverage finding" passes.

**Tombstones.** Suppress anything matching a rejected slug or claim, **unless** ≥3 sessions not in `sessionsAtRejection` now support it. When it does resurface, say plainly that it was rejected before and lead with the new evidence.

**One-off filter.** A thing you said once, in one repo, about one file, is not a lesson. It is a Tuesday.

**Scope classification.** Universal → `learned`. One repo → that project's memory. About a specific skill's behavior → `skill-edit`. Repeated multi-step workflow you hand-drive → `new-skill`. About your own prompting → `coaching`, which never becomes a rule for Claude.

Rank by `distinct_sessions` desc, then confidence. Take the top `--max` (default 12); hold the rest for next run.

---

## 7. Stage 5 — Approve

Nothing is written before this stage. Nothing.

Walk the surviving lessons through `AskUserQuestion`, **4 per call, one question each**. For each, the question text carries the claim, the occurrence count, the target file, and the strongest quote. Options:

1. **Accept** — apply as written. (Say the exact target path in the description.)
2. **Reject** — tombstone it. Say in the description that it can resurface on 3 new occurrences.
3. **Defer** — hold for next run, no tombstone.

The built-in "Other" is how you reword a lesson. If you type a rewording, use your text verbatim as the rule and treat it as accepted.

Present `skill-edit` and `new-skill` proposals with the actual diff or the draft's purpose in the question description. Those change behavior everywhere and deserve a closer read than a memory line.

Coaching findings are **not** put through approval. They go in the report (§9) and the coaching file. They are yours to act on, not rules for me.

---

## 8. Stage 6 — Apply

Only accepted lessons. Each one, by target:

**`learned`** → `~/.claude/retro/learned/<slug>.md`:
```markdown
---
name: <slug>
confidence: 0.85
first_seen: 2026-07-24
sessions: 3
---
<the rule, one or two sentences, imperative, ≤200 chars>
```
Keep the body short. It is injected into every session and the digest is capped — a long entry crowds out a better one.

**`project-memory`** → `~/.claude/projects/<project-slug>/memory/<slug>.md` in the standard memory format (`name`, `description`, `metadata.type` of `feedback` or `project`, body with **Why:** and **How to apply:**), plus a one-line pointer in that dir's `MEMORY.md`. The project slug is the cwd path with `/` replaced by `-`, e.g. `/Users/nickhwang/dev/ashby/Ashby` → `-Users-nickhwang-dev-ashby-Ashby`. Check for an existing memory covering the same ground and update it instead of adding a second.

**`skill-edit`** → Edit the target `SKILL.md`. Smallest change that lands the rule. Put it where the skill will actually read it, not in a trailing "notes" section. Re-read after editing to confirm the surrounding instructions still cohere.

**`new-skill`** → `~/.claude/skills/nick/skills/<name>/SKILL.md` with `user-invocable: true` and a description starting `DRAFT —`. Write it from the evidence: the steps you actually performed by hand, in order. Tell the user it is a draft and unrefined.

Append every applied lesson to `state.applied`.

---

## 9. Stage 7 — Close out

1. Write `coaching/<date>.md` if the coaching lens returned anything: the pattern, what it cost in rounds, and a concrete alternative. Be direct and not preachy. Skip the file entirely rather than padding it.
2. Update `state.json`: `lastSyncAt` = window end, append the run record, add tombstones, add applied entries.
3. On `--dry-run`, skip 1 and 2 completely and say so.
4. Print the report:

```
retro · <since> → <until> · <N> prompts, <M> sessions, <P> projects

APPLIED (<n>)
  ✓ <claim>
    → <target path>   <k> sessions
REJECTED (<n>)
  ✗ <claim>  (tombstoned, returns on 3 new)
DEFERRED (<n>)
  · <claim>

COACHING
  <2-4 bullets, or "nothing worth flagging">

NEXT
  Due <date>. Held over: <n> lessons.
```

Then one line: `DONE (verified)` with what was written, or `DONE_WITH_CONCERNS` and the risk.

---

## 10. Rules

- **Approval is absolute.** No file outside `runs/` is written before Stage 5. Not a "safe" memory line, not a typo fix.
- **Quote, don't characterize.** Every proposal carries verbatim evidence with a session id. A lesson you cannot quote is a lesson you invented.
- **One irritated message is not a policy.** A bad day is not a convention.
- **Prefer sharpening to adding.** The rule already existing and not landing is the most common real finding. Adding a fourth copy of it makes things worse.
- **Never touch `~/.claude/CLAUDE.md`.** It is hand-curated. If a lesson truly belongs there, propose it in the report as a manual edit and let the user make it.
- **Keep the learned digest small.** It costs context in every session. Over ~15 entries, propose retiring the weakest instead of appending.
- **Never read another person's data.** Only `~/.claude/projects/`.
- Follow the Voice rules in `~/.claude/CLAUDE.md` for the report and every rule you write.

---

## 11. Cadence

Manual. The SessionStart hook (`scripts/session-start.py`) mentions it once when more than `cadenceDays` have passed since `lastSyncAt`, and otherwise stays quiet. Change the interval by editing `cadenceDays` in `state.json`. Disable the nag by removing the hook from `~/.claude/settings.json`.
