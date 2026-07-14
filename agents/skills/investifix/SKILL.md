---
user-invocable: true
description: "Investigate an issue with adversarial multi-agent orchestration (competing root-cause hypotheses, mid-flight skeptic validators, a consolidation panel that gates on a score), implement the fix, simplify + de-slop it, then self-review the diff with a fresh adversarial panel — below the review gate (default 90%) an ultra ralph loop iterates the fix until it passes — then commit, push, and open a PR. Checkpoints each run to `.ignore/investigations/<slug>.md` so re-runs are cheap: unchanged → cached report; new commits → incremental re-investigation of the delta; `--force` → fresh. Invoke as `/investifix #123` (also accepts an issue URL or a freeform problem description). Flags: `--skip` (investigate only), `--quick`/`--light` (few agents), `--score N` (investigation gate, default 95), `--review-score N` (self-review gate, default 90), `--here`/`--no-worktree` (current worktree), `--force`/`--fresh` (ignore checkpoint), `--reply`/`--resolve` (automated-reviewer threads on the opened PR only — CodeRabbit/Lucille, never the issue or humans). Never comments on the issue or PR unless explicitly asked."
---

# investifix — adversarial investigate-then-fix

Take an issue, drive it to a high-score root cause with adversarial multi-agent orchestration, and — when a code change is warranted — implement it, simplify + de-slop it, then prove it survives a fresh adversarial self-review (an ultra ralph loop until it clears the gate) before shipping a PR.

`$ARGUMENTS` is either a GitHub issue ref (`#108114`, `108114`, or an issue URL) or a freeform problem description.

**Flags** (parse leading flags before resolving the target):
- `--skip` — investigation + report only; never modify code.
- `--quick` (alias `--light`) — lightweight: one investigator + one skeptic, inline consolidation, single round; a single-reviewer self-review with at most one corrective iteration. Phases 4–7 otherwise unchanged. For small/obvious issues.
- `--score N` — investigation consolidation gate percent (default `95`).
- `--review-score N` — implementation self-review gate percent (default `90`). The fresh reviewer panel in §Phase 6.5 must reach this before the fix ships.
- `--here` (alias `--no-worktree`) — implement on the current branch/worktree; skip the Phase 5 worktree.
- `--force` (alias `--fresh`) — ignore any checkpoint and re-investigate from scratch, then overwrite it.
- `--reply` / `--resolve` — *automated reviewers only.* Reply to / resolve the bot threads (CodeRabbit, Lucille, etc.) on the PR this skill opens. Never the issue, never human comments, never on your own initiative.

**Default (no flags):** resolve the checkpoint first (§Phase 0.5); when a full/incremental investigation runs, execute the pipeline above through to a shipped PR — no confirmation pause.

You call `/investifix` often and forget you already ran it. A full adversarial investigation is expensive, so re-runs are cheap by design — which means the **first** investigation must be immaculate: verify hypotheses, refute the weak ones, report an honest score, and record the real decision. Every later recall trusts the checkpoint, but still **re-checks the issue's latest state** first (new comments, closed/reopened).

> **Prose for humans** (reports, summaries, commit/PR text) gets a de-slop pass per the Voice rules in `~/.claude/CLAUDE.md`: trim filler, break up em-dash/semicolon pileups, warm up robotic phrasing. Never change a fact, score, or `file:line`. (Separate from the Phase 6 code de-slop.)

---

## Phase 0 — Intake & scope

1. Resolve the target:
   - **Input parses as an issue ref** (`#123`, `123`, or an issue URL) → `gh issue view <n> --json number,title,body,state,labels,assignees,url,comments`. Capture title, body, labels, and **all comments** — comments often hold the real repro and prior attempts. **If `gh` is missing/unauthenticated here, fail loudly** with a remediation (`"#123 looks like an issue but gh is unavailable — run \`gh auth login\` or pass a description"`) — do **not** silently investigate the literal token `#123` as freeform (that would investigate a meaningless string and derive a different slug than a working-`gh` run, breaking dedup).
   - **Input is genuinely freeform** (not an issue ref) → treat `$ARGUMENTS` as the problem statement and say so. Don't block on a tracker.
2. **Capture the main-repo root as an absolute path:** `ROOT=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")`. Use the *common* git dir, not `--show-toplevel`, so `ROOT` resolves to the original repo even when you're invoked from inside a linked worktree. Phase 5 may switch into a throwaway worktree and never switch back, so **every durable artifact (the scratch file and the checkpoint) is written under this `ROOT` by absolute path** — never a relative path, which would land in the disposable worktree and be lost.
3. Resolve the **slug** — must be **deterministic** so a recall finds the prior checkpoint:
   - GitHub issue → `issue-<number>`.
   - Freeform → `freeform-<hash>`. Compute `<hash>` **without putting the untrusted problem text on a command line** (it may contain `$(…)`, backticks, or quotes that a shell would execute): write the normalized statement (lowercased, whitespace-collapsed) to a temp file with the Write tool, then hash the file via stdin — `shasum < "$ROOT/.omc/research/.slug-input" | cut -c1-8`. Never interpolate the text into the command, and never use a model-written title.
4. Seed the scratch file at `$ROOT/.omc/research/investifix-<slug>.md` with the problem statement (findings accumulate here; the durable report lands at `$ROOT/.ignore/investigations/<slug>.md` in §Phase 8).
5. Capture the current HEAD SHA (`git rev-parse HEAD`) — the state you're investigating and the dedup key for recalls.
6. State the resolved target and plan in one or two lines, then begin.

---

## Phase 0.5 — Checkpoint recall (cheap re-runs)

Before spending agent time, decide whether this is really a new investigation. The checkpoint lives at `<ROOT>/.ignore/investigations/<slug>.md` (the Phase 0 absolute `ROOT`).

**Bot-thread path first** — before the `--force` short-circuit, since it's independent of caching and this is the only place it's reachable: if `--reply`/`--resolve` (or an explicit ask) is set **and** a checkpoint with a `pr:` exists, run the bot-thread reply/resolve step (see Notes) against that PR's live threads. Then fall through to the recall decision below (which `--force` may still send to FULL).

1. **`--force`** → **FULL** run; skip the rest.
2. **No checkpoint** → **FULL** run (first time).
3. **Checkpoint exists** — read its frontmatter (`sha`, `score`, `review_score`, `decision`, `pr`, `branch`, `date`, `last_comment_at`) and body. You have the current HEAD SHA (Phase 0) and, for a GitHub issue, its current `state` and comments.

   **`--skip` guard (applies to the whole table below):** `--skip` means *investigate/report only, never modify code*. If a branch below would enter a fix cycle (Phase 5/6.5) and `--skip` is set, instead re-verify and report only, then stop — never mutate. (Items 2/3/4 route through Phase 4, whose `--skip` stop enforces this; the Plateaued-fix resume states its own `--skip` stop inline.)

   **Plateaued-fix resume (evaluated before the SHA routing below).** If `decision` is `review-under-threshold` and the plateaued diff still exists — the stored `branch` has a non-empty diff, or (a `--here` plateau, no `branch`) the working tree still holds it — first check the issue's latest state (GitHub issue only; freeform has none). **Closed/resolved:** verify the root cause no longer applies, report `resolved`, refresh checkpoint (decision `resolved`), and stop. Don't resume the fix loop. **Otherwise (still open, genuinely reopened, or freeform with no issue to check):** resume the Phase 6.5 fix loop from the stored blocking findings **regardless of HEAD SHA drift**: re-enter the branch (Phase 5 step 1's existing-branch re-entry, which rebases onto the default branch if it moved), then continue the loop. Don't re-investigate. Honors `--skip` (report only). Only if the diff is genuinely gone (branch missing *and* working tree clean) fall through to the SHA routing below.

   - **HEAD SHA == checkpoint `sha`** → candidate **CACHED**. Print:
     `> Cached investigation — unchanged since <date> (SHA <short-sha>), score <score>%, decision: <decision>[, PR <pr>]. Re-run with \`--force\` to investigate again.`
     Then **always re-check the issue's latest state** and apply this **ordered, first-match-wins** table (top to bottom, stop at the first match — so orthogonal conditions can't collide). First compute `newest_seen` = newest timestamp among all issue comments — nothing to exclude, since this skill never posts issue comments (see Notes for the PR-side sentinel). If `last_comment_at` is **absent** on a GitHub-issue checkpoint (older checkpoint), treat it as epoch: every comment reads as new, so re-read once and write the field so it self-heals to a single re-check. (Freeform targets have no issue comments — the field never applies; skip this.)
     1. **issue closed/resolved** → verify the root cause no longer applies, report `resolved`, refresh checkpoint (decision `resolved`), stop.
     2. **decision `fix-shipped` with a stored `pr:`** → this is normally the healthy "shipped, awaiting merge" window, *not* a suspect verdict — do **not** re-fix on sight. Check the PR's live state (`gh pr view <pr> --json state,mergedAt`): **open/pending** → serve the cached report + PR link and stop (like item 8); **merged** → serve cached, but if the issue is still open (e.g. reopened because the fix regressed) re-verify the root cause via Phase 4 — if it reproduces, treat it as a rejected fix and re-fix (honors `--skip`); if it's resolved, refresh `resolved`; **closed unmerged** → the fix was rejected — re-verify the root cause via Phase 4 (honors `--skip`).
     3. **issue genuinely reopened** — now `open` while the checkpoint implies it was closed (decision `resolved`/`fix-shipped`, or a merged PR; the checkpoint stores no issue state, so reopening is inferred from the decision) → the prior verdict is suspect; re-verify the root cause reproduces via Phase 4 (honors `--skip`).
     4. **decision `investigate-only`** and no `--skip` this call → Phase 4 with the cached root cause (the user now wants the fix).
     5. **decision `review-under-threshold`** → handled by the Plateaued-fix resume pre-check above (which runs regardless of SHA); reaches here only if that pre-check found the diff gone → fall through to FULL.
     6. **decision `under-threshold`** → only re-investigate if the user asks (or `--force`); else serve the stored report and stop.
     7. **new material comments since `last_comment_at`** → scoped re-consolidation over the prior root cause + new comments (escalate to full only if they overturn it); refresh report + checkpoint.
     8. **else** → serve the stored report (+ PR link / issue state) and stop.
     In every branch, rewrite `last_comment_at` = `newest_seen` so an immaterial comment can't re-trigger on future runs.
   - **HEAD SHA != `sha`, and `sha` is an ancestor of HEAD** (`git merge-base --is-ancestor <sha> HEAD`) → **INCREMENTAL** (below).
   - **else** (`sha` is not an ancestor of HEAD — diverged lineage or unreachable after rebase/force-push) → **FULL** run; note it in the report.

**Incremental posture.** The delta is `git diff <checkpoint_sha>..HEAD`.
- If the delta plausibly **contains the recommended fix** (or the issue is now closed), verify whether the root cause still reproduces. If resolved, report **resolved by <commits>**, refresh the checkpoint (decision `resolved`), stop.
- Otherwise re-investigate **scoped to the delta**: hand investigators the prior root cause + the delta diff; ask them to (a) confirm the prior cause still holds and (b) surface only *new* causes from the delta. Reconcile with the prior report rather than re-deriving it. Then continue to Phase 4.

Announce the path in one line (e.g. `Incremental: 2 new commits since 2026-07-01 checkpoint — re-checking root cause against the delta.`).

---

## Phase 1–3 — Adversarial investigation (orchestrated)

The core. **Prefer the `Workflow` tool** (this invocation is explicit opt-in to multi-agent orchestration). If unavailable, fall back to parallel `Agent`/`Task`, then OMC `/team`. Run three pipelined phases; the throughline is **competing viewpoints, validation along the way, and a consolidation that only passes at a high score.**

> **Quick mode (`--quick`/`--light`):** skip the orchestration. Investigate directly (read the code, or delegate one pass to `oh-my-claudecode:debugger`), spawn **one** skeptic (`oh-my-claudecode:critic`) prompted to refute it, consolidate inline, assign the score, run a **single round**. Then continue to Phase 4.

### Phase 1 — Competing hypotheses (fan-out)
Spawn **3–5 independent investigators**, each assigned a *different* root-cause hypothesis so they compete rather than confirm one story. Distribute lenses across: the obvious cause · a data/state/persistence cause · a concurrency/ordering/timing cause · an integration/boundary/dependency cause · an environment/config/build cause.

Each returns structured output:
`{ hypothesis, evidenceFor[], evidenceAgainst[], codeLocations[] (file:line), repro?, score (0-100), proposedFix? }`

Use read-capable agents: `oh-my-claudecode:debugger`, `oh-my-claudecode:tracer` (competing-hypothesis specialist), `oh-my-claudecode:explore` (code mapping). In `Workflow`, pass via `opts.agentType`.

### Phase 2 — Skeptic validators (the adversarial pass)
For each surviving hypothesis, spawn a validator **prompted to refute it** ("Default to refuted=true unless the evidence is conclusive. Find the disconfirming case."). For high-stakes or close calls, use 2–3 validators with distinct lenses (does-it-reproduce, does-the-code-actually-do-this, alternative-explanation). Drop any hypothesis a majority refutes. Runs **as findings arrive** (pipeline), not as a barrier at the end.

### Phase 3 — Consolidation & score gate
A panel (`oh-my-claudecode:critic` + `oh-my-claudecode:architect`) takes the survivors and: (1) converges on the single best-supported root cause (or an explicit "multiple causes" / "cannot determine" verdict), (2) assigns a calibrated **score (0–100%)** with reasoning, (3) states whether a code change is needed and sketches the fix.

**Gate:** if score `< threshold` (default 95), loop back into Phase 1 with the panel's named gaps as new hypotheses/probes. Bound to **3 rounds**; if still under threshold, report the best finding with its score and the missing evidence. Never inflate the score.

> Reference `Workflow` shape (adapt counts, lenses, rounds to the issue):
> ```js
> // pipeline(): each hypothesis is validated the moment its investigation lands — no global barrier.
> const HYPS = [/* 3–5 lens prompts derived from the issue */]
> const investigated = await pipeline(
>   HYPS,
>   h => agent(h.prompt, {phase:'Investigate', agentType:'oh-my-claudecode:debugger', schema: HYP_SCHEMA}),
>   hyp => parallel(['reproduce','code-truth','alt-cause'].map(lens => () =>
>     agent(`Refute this hypothesis via the ${lens} lens. Default to refuted=true unless conclusive: ${JSON.stringify(hyp)}`,
>           {phase:'Validate', agentType:'oh-my-claudecode:critic', schema: VERDICT_SCHEMA})
>       .then(v => ({...hyp, lens, verdict: v})))),
> )
> const survivors = investigated.flat().filter(Boolean).filter(r => !r.verdict?.refuted)
> // then a consolidation agent over survivors → { rootCause, score, codeChangeNeeded, fixSketch }
> ```
> Loop the block while `score < threshold && round < 3`, feeding the panel's gaps in as the next round's hypotheses.

Write the consolidated report (root cause, key evidence for/against, score %, recommended fix or "no code change needed") to the scratch file and show a tight summary.

---

## Phase 4 — Decision

- `--skip` → present the report, write the checkpoint (§Phase 8, decision `investigate-only`), stop.
- Panel says **no code change needed** → present the report, checkpoint (decision `no-change-needed`), stop.
- Gate never reached threshold after 3 rounds → present the best finding, checkpoint (decision `under-threshold`), stop.
- Code change **warranted** → state the root cause, proposed fix, and files it touches in one or two lines, then proceed to implementation. No confirmation pause.

---

## Phase 5 — Implementation

1. **Isolate the work.** Unless `--here`, create a worktree: `wt switch --create <branch>` (fallback: `EnterWorktree`, then `git worktree add`). `<branch>` = `fix/issue-<n>` for a GitHub issue or `fix/<slug>` for a freeform target (`<slug>` is the Phase 0 slug — both are deterministic, so a re-run resolves the same branch). **Record `<branch>` in the checkpoint (§Phase 8)** so a `review-under-threshold` recall can re-enter it. Announce the branch.
   - **Branch/worktree already exists** (a re-run — the encouraged workflow — so this is expected): switch into the existing fix worktree instead of failing. If `wt switch --create` exits nonzero, fall back to `EnterWorktree`/`git worktree add`; never proceed as if it succeeded. **If the default branch has advanced since the branch was cut — or the branch's commits already landed on the default (a merged-then-reopened re-fix) — rebase onto the default branch, not onto the fix branch's own HEAD** (`git fetch origin && git rebase origin/<default>`, `<default>` from `git symbolic-ref --short refs/remotes/origin/HEAD` stripped of `origin/`; if that's unset, fall back to `git remote show origin | sed -n 's/.*HEAD branch: //p'`; if `<default>` still can't be resolved, skip the rebase and branch off HEAD instead) **before re-fixing**, so stale or already-merged commits don't leak into the re-opened PR. (If the rebase drops every commit as already-applied, that's expected — the new fix commits go on top.)
   - **`--here`/`--no-worktree`:** implement on the current branch in place, and say so — but first two guards. **(a) Default-branch guard:** compare `git rev-parse --abbrev-ref HEAD` to the repo default (`git symbolic-ref --short refs/remotes/origin/HEAD`, stripped of `origin/`; if that's unset, fall back to `git remote show origin | sed -n 's/.*HEAD branch: //p'`). If they match, the default can't be determined, or the branch is protected, **branch to `fix/…` first — never implement-and-push straight onto `main`/`master`.** **(b) Clean-tree guard:** unrelated uncommitted edits must not enter the review. Prefer a clean tree — if `git status --porcelain` is nonempty, stash first (or ask the user to). If it stays dirty, **scope the Phase 6/6.5 diff and cleanup to the explicit list of files the fix touches** (never the whole working tree), so in-progress edits aren't swept into the review, gate, or commit.
2. Delegate to `oh-my-claudecode:executor` (`deep-executor` for complex multi-file fixes). Hand it the consolidated report + exact `file:line` targets so it's grounded.
3. Add/update tests that capture the bug (`oh-my-claudecode:test-engineer`) when the fix is behavioral.
4. Verify with `oh-my-claudecode:verifier` (size the model per the verification guidance). Iterate until it passes — never proceed on a red verification.

---

## Phase 6 — Cleanup (only on the change just made)

Scoped to the diff just produced:
1. **Simplify** — `oh-my-claudecode:code-simplifier` over the changed files (behavior-preserving).
2. **De-slop** — `/oh-my-claudecode:ai-slop-cleaner` over the changed files (deletion-first).
3. **Re-verify** — re-run the verifier (or the new tests) to confirm these passes changed no behavior.

---

## Phase 6.5 — Adversarial self-review + ultra ralph loop (gate)

The first implementation iteration (Phases 5–6) produced a candidate fix that passes verification. Before shipping, turn the adversarial machinery on the fix itself — the same **competing viewpoints → validation → high-score consolidation** throughline, now aimed at the diff. Don't ship a fix that hasn't cleared its own review.

1. **Fresh reviewers only** — none that investigated or implemented this fix, so they come at the diff cold. Prefer `Workflow` (fall back to parallel `Agent`/`Task`, then `/team`). Distribute lenses, scaled to the change:
   - `oh-my-claudecode:code-reviewer` — correctness, API contracts, backward compatibility
   - `oh-my-claudecode:security-reviewer` — trust boundaries, injection, authz
   - `oh-my-claudecode:quality-reviewer` — logic defects, maintainability, performance
   - `oh-my-claudecode:test-engineer` — does the added/updated test actually capture the bug; coverage gaps
   - `oh-my-claudecode:critic` — prompted to **reject** ("Default to not-approved unless the diff fully and correctly fixes the root cause with no regressions. Find the disconfirming case.")

   Ground every reviewer in the consolidated root-cause report **and** the diff (`git diff` of the change just made). Each returns:
   `{ approved (bool), score (0-100), blockingFindings[] (file:line + why), nits[] }`

2. **Consolidate** into one **approval score (0–100%)** with reasoning and a deduped blocking-findings list. A finding a majority flag is blocking; a lone nit is not.

3. **Gate (default 90%, override with `--review-score N`):**
   - **score ≥ threshold** → record the score for the checkpoint and proceed to Phase 7.
   - **score < threshold** → **enter the ultra ralph loop.** Don't ship past a failed gate silently.

**Ultra ralph loop.** Iterate the *implementation* until it clears the gate — the boulder never stops until the review passes (or the bound trips). Drive it with `/oh-my-claudecode:ralph` + `ultrawork`, or inline with `Workflow`; the exit condition is the ≥ threshold gate, not a fixed round count. Each iteration:
1. Hand the blocking findings + current diff to `oh-my-claudecode:executor` (`deep-executor` for multi-file) and fix them; run independent fixes in parallel (ultrawork posture).
2. Re-run **Phase 6** cleanup on the new diff.
3. Re-verify (`oh-my-claudecode:verifier`) — must be green before re-review.
4. Re-review with a **new** fresh panel (step 1) and re-score.

Bound to **5 iterations**. If it plateaus below threshold, **stop and report honestly** — don't inflate, don't ship — and **write the checkpoint (§Phase 8, decision `review-under-threshold`)** recording the best `review_score` and the remaining blocking findings in the body, so a later `/investifix` recall (Phase 0.5) resumes this fix loop instead of re-investigating from scratch. Announce each iteration in one line (e.g. `Self-review 82% (<90) — fix round 2/5: 3 blocking findings.`).

> **Quick mode:** one reviewer (`oh-my-claudecode:critic`) over the diff, at most **one** corrective iteration if under threshold, then ship — quick mode may ship a single iteration under gate by design; record the honest `review_score` and note the shortfall in the body. No panel, no 5-round loop.

---

## Phase 7 — Ship

The implementation has cleared its Phase 6.5 gate.

1. Commit atomically. Conventional commit, add specific files by name — never `git add .`/`-A`, never commit secrets or `.env`. Reference the issue **only when there is one** (drop the `(#<n>)` trailer for a freeform target):
   ```
   fix: <concise description>[ (#<n>)]

   <one-line why, if not obvious>

   Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
   ```
2. Push: `git push -u origin HEAD` — but **never onto the default branch**. If HEAD is `main`/`master` (the Phase 5 `--here` guard should already have branched), branch to `fix/…` first; don't pollute the default branch.
3. Run **`/pr`** to open the pull request (handles draft mode and template; it adds `Relates to #<n>` from the branch name when there's an issue, and omits the trailer for a freeform target).
4. Write the checkpoint (§Phase 8, decision `fix-shipped`, with the PR URL and review score).
5. Return the PR URL and a two-line summary: root cause + score, and what changed.

---

## Phase 8 — Write the checkpoint (always; even a cached serve persists an advanced `last_comment_at`)

At whatever terminal point you reach — a Phase 4 stop, a `resolved` incremental exit, a **Phase 6.5 plateau** (`review-under-threshold`), or a Phase 7 ship — persist the durable report so the next `/investifix <target>` is cheap.

1. `mkdir -p "$ROOT/.ignore/investigations"` (the **absolute** `ROOT` from Phase 0 — see the Phase 0 note on why a relative path would be lost in a throwaway worktree). Make sure `.ignore/` is git-ignored (add to `.gitignore` or `.git/info/exclude` if not) so these artifacts never get committed.
2. Write `$ROOT/.ignore/investigations/<slug>.md` (overwriting any prior checkpoint) with frontmatter + the consolidated report as the body:

```markdown
---
target: "#108114"          # or "freeform: login-redirect-loop"
slug: issue-108114
sha: <full HEAD SHA that was investigated>   # the Phase 0 SHA — the dedup key
score: 96                  # honest investigation consolidation score
review_score: 92           # honest Phase 6.5 self-review score (present only when a fix was implemented)
decision: fix-shipped      # fix-shipped | no-change-needed | investigate-only | under-threshold | review-under-threshold | resolved
                           #   review-under-threshold = fix implemented but Phase 6.5 never cleared; body holds best review_score + remaining blocking findings; recall resumes the fix loop
pr: https://github.com/OWNER/REPO/pull/123   # present only when a PR was opened
branch: fix/issue-108114   # the Phase 5 fix branch; lets a review-under-threshold recall re-enter the worktree where the plateaued diff lives (omit if --here or no fix branch)
date: 2026-07-06           # today's date
last_comment_at: 2026-07-06T14:22:00Z   # the Phase 0.5 `newest_seen`: newest timestamp among ALL issue comments seen, so it always advances and an immaterial comment can't re-trigger the recall (GitHub issue only; omit for freeform)
---

<the consolidated report: root cause, key evidence for/against, score %, recommended fix or
"no code change needed", and — if shipped — what changed, the review score, and the PR link>
```

`sha` is the exact HEAD SHA you investigated (Phase 0) — the CACHED-vs-INCREMENTAL key. The checkpoint is written locally whether or not a PR was opened.

---

## Notes

- **Cheap re-runs by design** — see Phase 0.5 for the full recall taxonomy. A cache hit always re-checks the issue's latest state first.
- **Scale to the issue:** `--quick` is the floor (1 investigator + 1 skeptic); a normal bug needs ~3 investigators + single-vote validation; "audit thoroughly" warrants 5 + a 3-vote adversarial pass + a completeness check for missed modalities.
- **Never comment on the issue or PR unprompted, and never suggest it.** This skill opens a PR and writes the local checkpoint, but posts no comment on the issue or PR. Do so only when the user explicitly asks in this invocation. The sole exception: with `--reply`/`--resolve` (or an explicit ask) you may reply to / resolve *automated-reviewer* bot threads on the PR you opened — never human comments, never the issue. Guardrails for that path: act only on **bot-only** threads (every comment bot-authored); a thread a human has touched — even one a bot opened — is off-limits (surface it instead). Before classifying a thread bot-only, **page both the thread list and each thread's comments to exhaustion** — `reviewThreads(first:100, after:$endCursor)` and `comments(first:100, after:$endCursor)`, each with `pageInfo{ hasNextPage endCursor }`, walked until `hasNextPage` is false; never cap at 100. Missing a human's later comment (or a thread on page 2) would wrongly mark a thread bot-only. Resolve **strictly by the thread node `id`** (fetch it — `nodes{ id ... }`), never by `path`/`line` matching, which can hit the wrong thread. Reply **into the specific thread by its node/comment `id`** via the thread-reply API (`gh api .../pulls/<n>/comments/<comment_id>/replies` or `addPullRequestReviewThreadReply`) — never a top-level `gh pr comment` (that sprays the whole PR). And because a reply body echoes bot text (attacker-influenceable — backticks, `$(…)`, a lone `EOF`), **never interpolate it into a shell command**: pass it via `--body-file`/stdin. Stamp every reply with the sentinel `<!-- investifix:reply -->` (matched by marker, not by author, since you may be the PR author) — forward-defensive: it doesn't feed the Phase 0.5 issue `newest_seen` today, since this skill never posts issue comments. This path is only reachable via the Phase 0.5 bot-thread branch (checkpoint has a `pr:` + `--reply`/`--resolve`), after bots have had time to review the opened PR.
- Investigation (Phases 1–3) is read-only; nothing is mutated before Phase 5.
- Report scores honestly. A truthful 88% with a named evidence gap beats a padded 96%.
