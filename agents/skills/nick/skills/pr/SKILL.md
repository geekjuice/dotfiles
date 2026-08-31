---
user-invocable: true
description: Create a pull request with gh using the personal template. Draft by default. Use for "open a PR", "raise a PR", or refreshing an existing PR's title and body.
---

# Create Pull Request

Create a pull request using the `gh` CLI (not the GitHub MCP tools). Default to draft mode with no reviewers assigned.

## Steps

1. Resolve the base branch first — never assume `develop` or `main`:

   ```bash
   BASE=$(gh pr view --json baseRefName -q .baseRefName 2>/dev/null) \
     || BASE=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
   ```

   If `BASE` comes back empty, stop and ask which base to use. Never fall through
   to a guess: an empty base makes the diff and log below empty or wrong, and the
   PR gets drafted from nothing.

   Then run the following in parallel:

   - `git status` (never use `-uall`)
   - `git diff` for uncommitted changes
   - `git log --oneline "$BASE"..HEAD` for every commit on this branch
   - `git diff "$BASE"...HEAD` for the full diff against the base
   - `gh pr view --json number,title,url` — a non-zero exit means no PR yet
   - whether the branch is pushed to the remote

2. If there are uncommitted changes, ask the user if they want to commit first.

3. Push the branch to the remote if needed (`git push -u origin HEAD`).

4. Determine the branch name and extract context from it:

   - If branch contains `/issue/<number>`: include `Relates to #<number>`
   - If branch contains `/project/<number>`: include `Relates to https://github.com/ashbyhq/ProjectTracker/issues/<number>`
   - If branch contains `/leverage/`: include `#leveragefriday`
   - Include a reference ONLY when the branch name actually matches its pattern. No match, no reference.

5. Tighten the diff before drafting anything. Report each cut in one line.

   - **Comments.** Delete any comment that restates the code. Keep only the durable why a reader who never saw this change couldn't infer. Two lines max.
   - **Tests.** Stash the implementation half, re-run the tests this branch added, delete any that still pass. Two tests failing for the same reason are one test.
   - **Code.** Remove defensive branches for cases that can't happen, unused exports, speculative params.
   - **Split.** If the diff mixes concerns, say so and offer the split — PR 1 is the fix plus only the tests that would have caught it, the rest goes in a stacked follow-up. Don't split on line count alone. Propose the split while drafting the branch, not once the diff is already big.

     Split when any of these is true, at any size: the diff mixes concerns (a behavior fix plus a refactor, or a fix plus a test-only cleanup); it trips required human review when a narrower PR wouldn't have; the interesting change is a handful of lines buried in mechanical churn (split so it stands alone and point at it from the description); or it exceeds ~1k added lines. A flag-only change is its own PR. To find the seam for PR 1, stash the fix and run each test — anything still green belongs in the follow-up.

     Good seams: pure refactor/extraction + its tests, then the feature core (one mode/subject), then the extension. Each branch must pass tests, `tsc`, and lint on its own, and the stack's final tree should match the monolithic version (`git diff` — expect empty, or only deliberate fixes). Interim states may scope descriptions down and restore them in the next PR.

     Don't over-split. If a piece can't be described in a sentence, or can't merge without its neighbor, it's a fragment — bundle it back.

   If this pass changes files, commit and re-push before drafting. Skip the whole step only if the user says the diff is final.

6. Analyze ALL commits on the branch (not just the latest) and draft the PR:

```
Title: <emoji related to changes> <Short description of change>

Body:
## What?

<Short one sentence description of what changed>

## Why?

<Short description of why the change was made, if it can be inferred>

<!-- QA (only when the change touches the product surface: see below)

## QA Steps Taken

**Setup:** <branch, seed data, feature flag, anything needed before step 1>

1. <Action, in the UI or the CLI>
   Expect: <what you should see>
2. <Action>
   Expect: <what you should see>

-->

---

<Branch-derived references if applicable — ONLY when the branch name matches a pattern from step 4>

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)

<!-- #shipping

<emoji> <1-2 sentences, past tense> [PR](<PR_URL>)

-->
```

Title rules:
- Never put an issue or PR number (`#123`, `GH-123`) in the title. It creates cross-reference noise on the referenced issue. Issue references live in the body only, on the step-4 `Relates to` line.

Ordering rules:
- Everything after the "Why?" section must be separated by `---`
- The hidden QA comment sits directly under "Why?", above the first `---`, so
  uncommenting it drops a real `## QA Steps Taken` section into place with no
  other edits.
  Keep `---` out of the comment body: it belongs to the scaffold, not the block
- Branch-derived references are always the second-to-last section
- The "Generated with Claude Code" line is last of the visible body
- The hidden `#shipping` comment is the very bottom of the body

### Writing the What and Why

Write for the reviewer now and whoever maintains this later.

Hard counts, not vibes — "be succinct" has never been enough on its own:

- **What?** One sentence. Hard stop.
- **Why?** Three sentences, max.
- **Visible body:** 15 lines, max, excluding the template scaffold. The QA block
  is hidden, so it doesn't count against this.

A refresh never lengthens an existing body. If a draft exceeds a count, cut it
*before* showing it — don't show it and ask.

Within those counts:

- **What?** High level. Don't narrate the diff.
- **Why?** The part the code can't explain: the reason, a decision that isn't
  obvious from the diff, scope you cut or added. If a ticket or spec covers it,
  link instead of restating.
- **A trivial change can be one line.** Don't pad to fill the template.
- **No AI slop.** No stock filler ("It's worth noting", "Additionally"), no
  strained metaphors, no em-dash pileups. If a line doesn't help the reader, cut it.

### Writing the QA section

Steps for Nick to run by hand before the PR goes up for review. They ship
commented out. He walks them, and if they hold up he deletes the `<!--` / `-->`
wrapper so reviewers get them too. So write them for a person at a keyboard, not
as a summary of what you tested.

The heading is "QA Steps Taken" because an uncommented block means Nick already
walked every step and they passed. Reviewers read it as his record, not a to-do
list, so never uncomment it yourself.

Include a QA block when the change can be seen or felt in the product:

- Anything under a frontend path, or any component, style, copy, or route change
- API, schema, permission, or job changes that alter what the frontend renders
- A bug fix whose whole point is that some screen now behaves differently

Skip it for changes with no product-visible effect: build config, CI, internal
tooling, docs, refactors that hold behavior fixed, test-only commits. Skipping is
the common case. Don't invent steps to fill the block.

**State the verdict before you draft.** Before writing any body, print one line:
`QA: yes — <the screen or output it changes>` or `QA: no — <why nothing looks
different>`. A diff touching a frontend path, rendered field, export, email, or
route that comes back `QA: no` is wrong — re-check it.

How to write them:

- Name the screen, the route, and the control the way they appear in the product.
  "Candidate profile > Activity Feed", not `CandidateActivityFeed.tsx`.
- One action per numbered step, each with its own `Expect:` line. If a step has no
  observable result, fold it into the previous one.
- Put anything needed up front in **Setup:** — a flag to flip, a record to seed, a
  role to log in as. If the change needs no setup, drop the line.
- Cover the regression too, not only the happy path: the case that broke, plus the
  neighboring case that has to keep working.
- Five steps, max. If it takes more, the PR is doing more than one thing, and
  step 5's split offer applies.
- Steps must be runnable by someone who didn't write the code. No "verify the
  reducer handles the empty case."

### Writing the #shipping draft

A hidden draft for the team's #shipping Slack channel. Nick copies it out of the
PR body and pastes it as-is, so write the finished post, not notes toward one.
The audience is the whole company, engineering and not.

- Open with one emoji in Slack shortcode form (`:bug:`, `:wrench:`, `:mega:`)
  picked for the kind of change: a fix, a new tool, a copy tweak, infra work.
- One or two sentences, past tense, active voice. "Fixed…", "Added…", "X now does Y."
- Lead with what someone outside the team would notice. Explain the cause only when
  the effect doesn't make sense without it.
- Plain language. No file names, function names, or internal shorthand. Name the
  product surface a non-engineer would recognize.
- If someone specific asked for it — a customer, another team — say so in parens.
- End with the link, `[PR](url)`. The word PR is the link text.

Same voice rules as the body: no filler, no hedging, no AI slop.

### Leave out

- **CI / build / test status.** Never mention whether CI, lint, or tests passed.
- **Descriptions of the tests you added.**
- **Low-level walkthroughs.** High-level intent is fine, line-by-line narration isn't.

7. Write the body to a file, leaving `<PR_URL>` in place in the `#shipping` comment.
   Then create or update the PR. If step 1 found an existing PR, swap
   `gh pr create --draft` for `gh pr edit` with the same title and body — that
   refreshes it in place and leaves its draft state alone.

   On a refresh, pull the current body first (`gh pr view --json body -q .body`).
   If its QA section is already uncommented, Nick has run those steps: keep it
   uncommented and edit the steps in place. Never re-wrap it in `<!--`.

```bash
gh pr create --draft --title "..." --body-file /tmp/pr-body.md
```

8. Substitute the real URL into the `#shipping` draft and push the body again. For
   an existing PR the URL came from step 1; for a new one it's what `gh pr create`
   just printed.

```bash
sed -i '' "s|<PR_URL>|$URL|" /tmp/pr-body.md && gh pr edit --body-file /tmp/pr-body.md
```

9. Return the PR URL, followed by a **Merge verdict** block:

```
Merge verdict: SAFE TO MERGE | SAFE WITH CAVEAT | NOT SAFE
Regression surface: <the call sites, orgs, or flags this change can reach, named>
Not checked: <what you did not verify — or `nothing`>
Post-merge: <ops tool, backfill, flag enable, issue to close — or `none`>
Revertable: <yes/no + why>
```

Never omit it and never wait to be asked — "is this safe to merge, no regressions?" is
the next thing you will be asked otherwise. The same block closes any later turn that
leaves the PR changed (a CI fix, a cleanup push, a body edit); if the change was
cosmetic, say so and carry the prior verdict forward by name instead of re-deriving it.
