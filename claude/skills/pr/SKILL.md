---
user-invocable: true
description: Create a pull request using personal template
---

# Create Pull Request

Create a pull request using the `gh` CLI (not the GitHub MCP tools).

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

   - If branch contains `/issue/<number>`: include `Relates to #<number>` in the body
   - If branch contains `/project/<number>`: include `Relates to https://github.com/ashbyhq/ProjectTracker/issues/<number>` in the body
   - If branch contains `/leverage/`: include `#leveragefriday` in the body

5. Analyze ALL commits on the branch (not just the latest) and draft the PR:

```
Title: <emoji related to changes> <Short description of change>

Body:
## What?

<Short one sentence description of what changed>

## Why?

<Short to medium length description of why the changes were made if it can be inferred>

---

<Branch-derived references if applicable>
```

6. Create the PR using `gh pr create` with a HEREDOC for the body:

```bash
gh pr create --title "..." --body "$(cat <<'EOF'
...
EOF
)"
```

7. Check if a PR already exists for the current branch (`gh pr view --json number,title,url`).
   - If a PR exists, update its title and body using `gh pr edit` with the newly generated content.
   - If no PR exists, create one using `gh pr create`.

8. Return the PR URL when done.

## Re-running on an existing PR

If this skill is invoked on a branch that already has an open PR, it will regenerate the title and description based on the current state of all commits and update the existing PR. This is useful when the PR has evolved over time and needs a refreshed title/description.
