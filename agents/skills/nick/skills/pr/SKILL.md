---
user-invocable: true
description: Create a pull request using personal template
---

# Create Pull Request

Create a pull request using the `gh` CLI (not the GitHub MCP tools). Default to draft mode with no reviewers assigned.

## Steps

1. Run the following in parallel to understand the current state:

   - `git status` (never use `-uall`)
   - `git diff` for any uncommitted changes
   - `git log --oneline develop..HEAD` to see all commits on this branch
   - `git diff develop...HEAD` to see the full diff against the base branch
   - Check if the branch has been pushed to the remote

2. If there are uncommitted changes, ask the user if they want to commit first.

3. Push the branch to the remote if needed (`git push -u origin HEAD`).

4. Determine the branch name and extract context from it:

   - If branch contains `/issue/<number>`: include `Relates to #<number>`
   - If branch contains `/project/<number>`: include `Relates to https://github.com/ashbyhq/ProjectTracker/issues/<number>`
   - If branch contains `/leverage/`: include `#leveragefriday`
   - ONLY include these references when the branch name actually contains the matching pattern. Do NOT include `#leveragefriday` or any other tag unless the branch name explicitly matches.

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
- Never put an issue or PR number (`#123`, `GH-123`) in the title. GitHub turns it into cross-reference noise on the referenced issue/PR. Issue references live in the body only — the `Relates to` line from step 4.

Ordering rules:
- Everything after the "Why?" section must be separated by `---`
- Branch-derived references are always the second-to-last section
- The "Generated with Claude Code" line is always last

### Writing the What and Why

The description is for humans: the reviewer now, and whoever maintains this code
later (often the more important reader). Write for them.

- **Be succinct.** Only include what's necessary. Short sentences, plain words.
  A trivial change can be a single line — don't pad it out to fill the template.
- **What?** One sentence on what changed at a high level. Don't narrate the diff
  line by line; the reader can read the code.
- **Why?** This is the part code can't explain. Capture the reason for the change,
  a decision that isn't obvious from the diff, or scope you deliberately cut or
  added. If a linked ticket or spec already explains it, link to it instead of
  restating it.
- **No AI slop.** No stock filler ("It's worth noting", "Additionally"),
  no strained analogies or metaphors, no em-dash pileups. If a line doesn't help
  the reader, cut it. Read it back and make sure a human would actually write it.

### Leave out

- **CI / build / test status.** Never mention whether CI, linting, or tests passed
  or failed. That's visible in the GitHub UI and it's just noise here.
- **Descriptions of the tests you added.** The code shows that.
- **Low-level walkthroughs of the code.** High-level intent is fine; line-by-line
  narration isn't.

6. Create the PR using `gh pr create` with a HEREDOC for the body:

```bash
gh pr create --draft --title "..." --body "$(cat <<'EOF'
...
EOF
)"
```

7. Check if a PR already exists for the current branch (`gh pr view --json number,title,url`).
   - If a PR exists, update its title and body using `gh pr edit` with the newly generated content.
   - If no PR exists, create one using `gh pr create --draft`.

8. Return the PR URL when done.

## Re-running on an existing PR

If this skill is invoked on a branch that already has an open PR, it will regenerate the title and description based on the current state of all commits and update the existing PR. This is useful when the PR has evolved over time and needs a refreshed title/description.
