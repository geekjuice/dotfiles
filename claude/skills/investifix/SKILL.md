---
user-invocable: true
description: "Investigate an issue with adversarial multi-agent orchestration (competing root-cause hypotheses, skeptic validators mid-flight, a consolidation panel that gates on a score), then implement the fix, simplify + de-slop it, commit, push, and open a PR. Invoke as `/investifix #123` (also accepts an issue URL or a freeform problem description). Flags: `--skip` (investigate only), `--quick`/`--light` (lightweight, few agents), `--score N` (gate threshold, default 95), `--here`/`--no-worktree` (work in the current worktree instead of creating a new one)."
---

# investifix — adversarial investigate-then-fix

Take an issue, drive it to a high-score root cause using adversarial multi-agent
orchestration, and — when a code change is warranted — implement it, clean it up, and ship a PR.

The input (`$ARGUMENTS`) is one of:
- a GitHub issue ref: `#108114`, `108114`, or a full issue URL
- a freeform problem description (no tracker)

Parse leading flags from the arguments before resolving the target:
- `--skip` — investigation + report only; never modify code.
- `--quick` (alias `--light`) — lightweight mode: skip the multi-agent orchestration; one investigator + one skeptic, inline consolidation, single round. Phases 4–7 (fix → cleanup → PR) are unchanged. Use for small/obvious issues.
- `--score N` — consolidation gate threshold as a percent (default `95`).
- `--here` (alias `--no-worktree`) — implement the fix in the current worktree on the current branch; skip creating a new worktree in Phase 5. Everything else (investigation, cleanup, commit, push, PR) is unchanged.

Default behavior (no flags): investigate to a >=95% score, then implement the fix (when one is
warranted), simplify + de-slop it, commit, push, and open a PR — no confirmation pause.

---

## Phase 0 — Intake & scope

1. Parse flags, then resolve the target:
   - If it looks like a GitHub issue and `gh` is installed and the cwd is a repo:
     `gh issue view <n> --json number,title,body,state,labels,assignees,url,comments`
     Capture the title, body, labels, and **all comments** — comments often hold the real repro and prior attempts.
   - If `gh` fails or there is no number (freeform input), treat `$ARGUMENTS` as the problem statement and say so. Do not block on a tracker.
2. Write a scratch tracking file at `.omc/research/investifix-<target>.md` (create the dir if needed) seeded with the problem statement. Findings and the final report accumulate here.
3. State the resolved target and the plan in one or two lines, then begin. Do not narrate further.

---

## Phase 1–3 — Adversarial investigation (orchestrated)

This is the core. **Prefer the `Workflow` tool** — this skill invocation is explicit opt-in to
multi-agent orchestration, so calling `Workflow` is authorized here. If `Workflow` is unavailable,
fall back (in order) to parallel `Agent`/`Task` calls, then OMC `/team`.

> **Quick mode (`--quick`/`--light`):** skip the orchestration below. Investigate directly —
> read the relevant code yourself, or delegate **one** pass to `oh-my-claudecode:debugger` — then
> spawn **one** skeptic (`oh-my-claudecode:critic`) prompted to refute the finding. Consolidate
> inline, assign the score, run a **single round** (no 3-round loop, no Workflow, no fan-out).
> Then continue to Phase 4 unchanged. Reserve full mode for ambiguous, cross-cutting, or high-stakes issues.

Run three pipelined phases. The throughline the user always wants: **competing viewpoints,
validation along the way, and a consolidation pass that only passes at a high score.**

### Phase 1 — Competing hypotheses (fan-out)
Spawn **3–5 independent investigators**, each assigned a *different* root-cause hypothesis so they
genuinely compete rather than confirm one story. Good lenses to distribute across agents:
- the obvious / first-read cause
- a data / state / persistence cause
- a concurrency / ordering / timing cause
- an integration / boundary / dependency cause
- an environment / config / build cause

Each investigator returns, as structured output:
`{ hypothesis, evidenceFor[], evidenceAgainst[], codeLocations[] (file:line), repro?, score (0-100), proposedFix? }`

Use read-capable agents: `oh-my-claudecode:debugger`, `oh-my-claudecode:tracer` (competing-hypothesis
specialist), and `oh-my-claudecode:explore` for code mapping. In `Workflow`, pass these via `opts.agentType`.

### Phase 2 — Skeptic validators (the adversarial pass)
For each surviving hypothesis, spawn a validator **prompted to refute it**, not confirm it
("Default to refuted=true unless the evidence is conclusive. Find the disconfirming case.").
For high-stakes or close calls, use 2–3 validators per hypothesis with distinct lenses
(does-it-reproduce, does-the-code-actually-do-this, alternative-explanation). Drop any hypothesis a
majority refutes. This runs **as findings arrive** (pipeline), not as a single barrier at the end.

### Phase 3 — Consolidation & score gate
A consolidation panel (`oh-my-claudecode:critic` + `oh-my-claudecode:architect`) takes the survivors and:
1. converges on the single best-supported root cause (or an explicit "multiple causes" / "cannot determine" verdict),
2. assigns a calibrated **score (0–100%)** with the reasoning behind it,
3. states whether a code change is needed and sketches the fix.

**Gate:** if the score `< threshold` (default 95), loop back into Phase 1 with the specific gaps the
panel identified as new hypotheses/probes. Bound this to **3 rounds**; if still under threshold, stop
and report the best finding with its score and exactly what evidence is missing to close the gap.
Never inflate the score to pass the gate — report the real number.

> Reference `Workflow` shape (adapt freely — counts, lenses, and rounds scale to the issue):
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
> const survivors = investigated.flat().filter(Boolean)
>   .filter(r => !r.verdict?.refuted)
> // then a consolidation agent over survivors → { rootCause, score, codeChangeNeeded, fixSketch }
> ```
> Loop the whole block while `score < threshold && round < 3`, feeding the panel's named gaps back in as the next round's hypotheses.

Write the consolidated report (root cause, key evidence for/against, score %, recommended fix or
"no code change needed") to the scratch file and show a tight summary to the user.

---

## Phase 4 — Decision

- `--skip`, or the panel says **no code change is needed** → present the report and stop. Done.
- A code change **is** warranted → state the root cause, the proposed fix, and the files it will touch
  in one or two lines, then proceed straight to implementation. No confirmation pause.

---

## Phase 5 — Implementation

1. Create an isolated worktree before editing (per personal worktree workflow):
   `wt switch --create fix/issue-<n>-<short-slug>` (fallback: `EnterWorktree` tool). Announce the branch.
   **If `--here`/`--no-worktree` was passed:** skip this step entirely — stay in the current worktree and implement on the current branch. Announce that you're working in place.
2. Delegate the implementation to `oh-my-claudecode:executor` (use `oh-my-claudecode:deep-executor`
   for complex, multi-file fixes). Hand it the consolidated report + exact file:line targets so it is grounded.
3. Add or update tests that capture the bug (`oh-my-claudecode:test-engineer`) when the fix is behavioral.
4. Verify the fix with `oh-my-claudecode:verifier` (size the model per the verification guidance). Iterate until it actually passes — do not proceed on a red verification.

---

## Phase 6 — Cleanup (only on the change just made)

Run both, scoped to the diff just produced:
1. **Simplify** — `oh-my-claudecode:code-simplifier` agent over the changed files (clarity/consistency, behavior-preserving).
2. **De-slop** — `/oh-my-claudecode:ai-slop-cleaner` over the changed files (deletion-first slop cleanup).
3. **Re-verify** — these passes must not change behavior; re-run the verifier (or the new tests) to confirm green.

---

## Phase 7 — Ship

1. Commit atomically. Conventional commit, reference the issue, and add specific files by name —
   never `git add .`/`-A`, never commit secrets or `.env`:
   ```
   fix: <concise description> (#<n>)

   <one-line why, if not obvious>

   Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
   ```
2. Push the branch: `git push -u origin HEAD`.
3. Run the **`/pr`** skill to open the pull request (it handles draft mode, template, and `Relates to #<n>` from the branch name).
4. Return the PR URL and a two-line summary: root cause + score, and what was changed.

---

## Notes

- Scale the agent count and validator depth to the issue: `--quick` is the floor (1 investigator + 1 skeptic); a normal bug needs ~3 investigators and single-vote validation; "audit this thoroughly" warrants the full 5 + 3-vote adversarial pass + a completeness check for missed modalities.
- Investigation (Phases 1–3) is read-only and safe to re-run; nothing is mutated before Phase 5.
- If the input is freeform (no tracker), Phase 7 still works — `/pr` derives references from the branch name, so name the branch with the issue number when there is one.
- Report the score honestly. A truthful 88% with a named evidence gap is more useful than a padded 96%.
