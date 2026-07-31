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

5. Analyze ALL commits on the branch (not just the latest) and draft the PR:

```
Title: <emoji related to changes> <Short description of change>

Body:
## What?

<Short one sentence description of what changed>

## Why?

<Short description of why the change was made, if it can be inferred>

---

<Branch-derived references if applicable — ONLY when the branch name matches a pattern from step 4>

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

Title rules:
- Never put an issue or PR number (`#123`, `GH-123`) in the title. It creates cross-reference noise on the referenced issue. Issue references live in the body only, on the step-4 `Relates to` line.

Ordering rules:
- Everything after the "Why?" section must be separated by `---`
- Branch-derived references are always the second-to-last section
- The "Generated with Claude Code" line is always last

### Writing the What and Why

Write for the reviewer now and whoever maintains this later.

- **Be succinct.** A trivial change can be one line. Don't pad to fill the template.
- **What?** One sentence, high level. Don't narrate the diff.
- **Why?** The part the code can't explain: the reason, a decision that isn't
  obvious from the diff, scope you cut or added. If a ticket or spec covers it,
  link instead of restating.
- **No AI slop.** No stock filler ("It's worth noting", "Additionally"), no
  strained metaphors, no em-dash pileups. If a line doesn't help the reader, cut it.

### Leave out

- **CI / build / test status.** Never mention whether CI, lint, or tests passed.
- **Descriptions of the tests you added.**
- **Low-level walkthroughs.** High-level intent is fine, line-by-line narration isn't.

6. Create or update the PR, using a HEREDOC for the body. If step 1 found an
   existing PR, swap `gh pr create --draft` for `gh pr edit` with the same title
   and body — that refreshes it in place and leaves its draft state alone.

```bash
gh pr create --draft --title "..." --body "$(cat <<'EOF'
...
EOF
)"
```

7. Return the PR URL.
