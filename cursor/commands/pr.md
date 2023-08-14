### Create Pull Request

Purpose: Create a Pull Request using `gh`

Do exactly the following:

1. Preconditions & tooling

   - Verify Git is available: `git --version`.
   - Verify GitHub CLI is available: `gh --version`.
   - Verify you’re authenticated with GitHub: `gh auth status`.
     - If not authenticated, stop and output: **"GitHub CLI not authenticated. Run: gh auth login"**.

2. Detect repo & branch state

   - Ensure we are inside a Git repo; if not, stop with **"Not a git repository."**.
   - Determine the current branch: `git rev-parse --abbrev-ref HEAD` (call this `$BRANCH`).
   - If `$BRANCH` equals `main` or `master`, warn: **"You are on $BRANCH. PRs should come from a feature branch."** and continue only if the user replies exactly `ok`.
   - Check for uncommitted changes: `git status --porcelain=v1 -z`.
     - If there are unstaged/unstashed changes, ask: **"There are local changes. Reply 'stash' to stash, 'commit' to continue after committing, or 'cancel' to abort."**
       - If `stash`, run `git stash -u -m "temp-pr-stash"` and continue.
       - If `commit`, stop with **"Please commit and re-run the command."**
       - If `cancel`, stop.
   - Check if the branch is ahead/behind remote:
     - Fetch: `git fetch -q`.
     - If branch has no upstream, set upstream when pushing in step 3.

3. Push branch if needed

   - If not pushed: `git push -u origin "$BRANCH"`; on error, stop and report the error.
   - If behind remote, prompt: **"Your branch is behind remote. Reply 'merge' to merge main, 'rebase' to rebase on main, or 'skip' to continue."**
     - For `merge`: `git fetch origin main && git merge --no-edit origin/main`.
     - For `rebase`: `git fetch origin main && git rebase origin/main`.
     - For `skip`: continue.

4. Determine target base branch

   - Infer target base branch, e.g., `develop`, `main`, `master`
   - Call this `$BASE`.

5. Collect metadata for the PR

   - Propose a PR title using the following template:
     - [`emoji`] `Short summary of change` where `emoji` can be some image based on the type of changes or topics of the change.
     - Ask the user: **"Proposed title: '<title>'. Reply with a new title or 'ok' to accept."**
   - Detect linked issues in branch or commits (e.g., `ABC-123`, `#123`):
     - Grep branch name and last 20 commit messages for patterns: `#[0-9]+` and `[A-Z]{2,}-[0-9]+`.
     - Build a `Relates/Closes` footer suggestion: e.g., `Closes #123` if an issue reference is present.

6. Use the PR template

   - Use the following template in `$BODYFILE` with the following markdown sections (keep headings exactly; leave empty subsections out):

     ```
     ## What?
     <1-3 sentences problem statement / motivation>

     ## Why?
     <why now / background / any relevant tickets or docs>

     ## Screenshots
     <drag & drop images, or paste recording links>

     ## Related
     <Closes #123 / Relates ABC-123 / Docs link>

     ```

7. Preview before creating

   - Show a structured preview:
     ```
     PR Title: <title>
     Base: <base>   Head: <branch>
     Body (first 40 lines):
     --------------------------------
     <body preview>
     --------------------------------
     ```
   - Ask the user: **"Reply 'create' to open the PR, 'edit body' to revise the body, 'edit title' to change the title, or 'cancel' to abort."**
     - If `edit body`, open `$BODYFILE` in `$EDITOR` if set, else ask for inline replacement and write to `$BODYFILE`.
     - If `edit title`, capture new title and update.

8. Create the PR with `gh`

   - Run exactly (compose args conditionally):
     - `ARGS=( pr create --base "$BASE" --head "$BRANCH" --title "$TITLE" --body-file "$BODYFILE" )`
     - Execute: `gh "${ARGS[@]}"`
   - On success, capture PR URL: `gh pr view --json url --jq .url` and print:
     - **"PR created: <url>"**
   - If creation fails due to missing permissions (e.g., forks), output the error and stop.

9. Cleanup

   - Remove any temp files created for `$BODYFILE`.
