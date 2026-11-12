---
user-invocable: true
description: "Remove an Ashby feature flag: find every reference, decide one PR or two, strip usage keeping the on-path, retire the definition with the 2-week date, verify, and open draft PRs labeled Flag Fling. Use for 'remove the X flag', 'fling X', 'clean up flag X', or /nick:flagfling FlagName."
---

# flagfling

Remove one `UserFeatureFlags` member from the Ashby monorepo. House rules come from the ops "Flag Fling"
prompt (`operations_frontend/src/components/FeatureFlag/FeatureFlagCursorRemovalPrompt.tsx`). Re-read it
first: if it changed, it wins on house rules. The two-PR date convention is Nick's (from #113575/#113577
and #110825/#110826).

Args: the flag name (required). `--segment fullProduct|allAnalytics|greenhouse|lever|workday` when the
flag was on for one org segment only: swap each check for the segment check the prompt gives, not `true`.

## 1. Preflight

- Read the flag's entry in `shared/src/feature_flags.ts`: category, author, `defaultOn*`.
- Removal keeps the on-path. If the category isn't `ToRemove*` (e.g. `EarlyAccess`, `Development`), say
  in one line that merging ships the behavior to every org, and that prod enablement wasn't checked.
  Never query prod. Don't block: the invoke is the ask.
- Worktree: `/worktrunk:wt-switch-create nickhwang/remove-<kebab-flag>-flag`. Then run
  `./scripts/setup-worktree.sh --fast` in the background (~3 min) and edit while it runs. When it
  finishes, `yarn --cwd=shared build`: setup builds `shared` before your edits land.

## 2. Find references, pick the path

- `git grep -n <Flag>` in the worktree.
- The Chrome Extension ships on its own, so its last three releases count:
  - `git tag -l | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -3`, checked against
    `git ls-remote --tags origin`. Skip `git fetch --tags`: it runs for minutes.
  - `git grep -n <Flag> <t1> <t2> <t3> -- chrome_extension/` (exit 1 = none).
  - Positive control: `git grep -c "UserFeatureFlags\." <t3> -- chrome_extension/` must hit.
- Print the verdict before editing:
  - `PRs: 1 — backend only`: every hit is under `backend/`, the definition in `shared/src/feature_flags.ts`,
    or `eslint.no-restricted-imports.config.mjs`, and no release tag hits.
  - `PRs: 2 — referenced in <dirs>` otherwise. A release-tag hit counts as outside; say so in PR 1's body.

## 3. Remove usage (both paths)

- `isFlagActiveForOrg(UserFeatureFlags.<Flag>)` and `useFeatureFlagEnabled(...)` become `true` (or the
  segment check). Fold the constant: drop the variable, dead branches, and imports left unused.
- Rewrite or cut comments that mention the flag, by name or in prose ("the flag gates…").
- Tests:
  - Delete `setFeatureFlagEnabled({ title: UserFeatureFlags.<Flag> })` and in-memory equivalents.
  - A test that turns the flag OFF to prove the off-path: delete it, or repoint it at what still applies
    (e.g. drop the fixture that is now always offered). Never keep a test asserting dead behavior.
  - Rename `describe` blocks named after the flag to what they test.

## 4a. One PR (backend only)

- Delete the enum member and its `userFeatureFlagConfig` entry. Drop it from
  `eslint.no-restricted-imports.config.mjs` if listed.
- Title: `🚩 Remove <Flag> [usage and definition]`.

## 4b. Two PRs (referenced outside backend)

`DATE` = the day PR 1 is created + 14 days (`date -v+14d +%F`). Both PRs open the same day.

**PR 1**: branch `nickhwang/remove-<kebab-flag>-flag-usage`, title `🚩 Remove <Flag> [usage only]`.
- Keep the definition. Set `category: FeatureCategory.ToRemoveFullyRolledOut`, add
  `markedForRemovalAt: "<DATE>"`, and `defaultOnForTests: true` if it isn't already.
- Add the flag, alphabetically, to the stale-flag list in `eslint.no-restricted-imports.config.mjs` whose
  `message` matches its rollout scope ("All orgs", "Full product orgs", "Analytics orgs").
- Bump `FRONTEND_APP_VERSION` in `shared/src/version_control.ts` to the next major (`245.0.0` → `246.0.0`).
- Body also says: "This only removes usages. Since this flag is referenced outside of the backend folder,
  the definition will be cleaned up automatically later."

**PR 2**: branch `nickhwang/remove-<kebab-flag>-flag-definition`, cut from PR 1's branch, base = PR 1's
branch, title `🚩 Remove <Flag> [definition]`, draft.
- Delete the enum member and config entry, and the ESLint entry PR 1 added.
- Banner directly under the What? sentence, same `DATE` as `markedForRemovalAt`:

  ```
  > [!NOTE]
  > Merge after <Month D, YYYY>
  ```

- Why? opens with "Stacked on #<PR 1>, which removed the last flag read."
- If PR 1 merges on a later day, move both dates to merge day + 14: `markedForRemovalAt` on PR 1 (or on
  PR 2 if PR 1 already merged) and the banner on PR 2.

## 5. Verify (each PR on its own)

- `git grep -n <Flag>`: zero hits, or for PR 1 only the definition and the ESLint entry.
- `yarn --cwd=shared build`, then only the touched test files:
  `DISABLE_TEST_LOGS=true yarn --cwd=backend test -- <paths>`. First check that no peer run holds
  `ashby_test`: `ps -axo pid,etime,command | grep '[v]itest run'`.
- `yarn --cwd=backend typecheck`. It's silent on success; the exit code is the evidence. If the frontend
  was touched: `yarn --cwd=frontend compile`.
- `yarn --cwd=<pkg> exec eslint <files>` and `yarn exec oxfmt --check --ignore-path .oxfmtignore <files>`.
- One independent `code-reviewer` (sonnet) pass on the diff: leftover references and prose, on-path
  equivalence, unused imports, tests that still prove their names.

## 6. Ship

- Commit the named files: `chore: remove <Flag> flag`.
- Open each PR per /nick:pr (draft, What/Why, #shipping draft, merge verdict), with:
  - What? = "Remove <Flag> because it is fully rolled out or stale (see https://operations.ashbyhq.com/feature_flags/stale)."
  - `--label "Flag Fling 🚩🗑️"`.
  - Why? names the on-path consequence when the flag wasn't already on everywhere.
- After merge (optional): mark the flag retired on the ops feature-flags page.

## Traps

- The worktree isolation hook refuses loops and compound `git`/`gh` lines (`for t in …`, a `-q` jq
  string with `\(.x)\n`). One plain command per call.
- `yarn --cwd` can silently no-op in some worktrees. One
  `yarn --cwd=backend exec node -e "console.log(process.cwd())"` proves it works.
- Flag sync (`featureFlagOperationsObjectHaven.syncFeatureFlags`) only upserts. A removed definition
  leaves an inert `feature_flag` row, so there's no deploy risk.
- The ops stale page reads `markedForRemovalAt` as days since the mark, so a future date shows a negative
  age until then. Expected.
