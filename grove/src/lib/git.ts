import { simpleGit, SimpleGit } from "simple-git";
import { resolve, basename } from "node:path";
import { existsSync } from "node:fs";

export type WorktreeInfo = {
  path: string;
  branch: string;
  head: string;
  isMain: boolean;
  isBare: boolean;
}

export type WorktreeStatus = {
  worktree: WorktreeInfo;
  modified: number;
  staged: number;
  untracked: number;
  ahead: number;
  behind: number;
  isDirty: boolean;
}

export function getRepoName(repoRoot: string): string {
  return basename(repoRoot);
}

export async function getGit(cwd?: string): Promise<SimpleGit> {
  const git = simpleGit(cwd);
  return git;
}

export async function getRepoRoot(cwd?: string): Promise<string> {
  const git = await getGit(cwd);
  const root = await git.revparse(["--show-toplevel"]);
  return root.trim();
}

export async function listWorktrees(cwd?: string): Promise<WorktreeInfo[]> {
  const git = await getGit(cwd);
  const result = await git.raw(["worktree", "list", "--porcelain"]);

  const worktrees: WorktreeInfo[] = [];
  let current: Partial<WorktreeInfo> = {};

  for (const line of result.split("\n")) {
    if (line.startsWith("worktree ")) {
      current.path = line.slice(9);
    } else if (line.startsWith("HEAD ")) {
      current.head = line.slice(5);
    } else if (line.startsWith("branch ")) {
      current.branch = line.slice(7).replace("refs/heads/", "");
    } else if (line === "bare") {
      current.isBare = true;
    } else if (line === "detached") {
      current.branch = current.branch || "(detached)";
    } else if (line === "") {
      if (current.path) {
        worktrees.push({
          path: current.path,
          branch: current.branch || "(unknown)",
          head: current.head || "",
          isMain: worktrees.length === 0,
          isBare: current.isBare || false,
        });
      }
      current = {};
    }
  }

  return worktrees;
}

export async function getWorktreeStatus(
  worktree: WorktreeInfo
): Promise<WorktreeStatus> {
  if (worktree.isBare || !existsSync(worktree.path)) {
    return {
      worktree,
      modified: 0,
      staged: 0,
      untracked: 0,
      ahead: 0,
      behind: 0,
      isDirty: false,
    };
  }

  const git = await getGit(worktree.path);

  try {
    const status = await git.status();
    return {
      worktree,
      modified: status.modified.length + status.deleted.length,
      staged: status.staged.length,
      untracked: status.not_added.length,
      ahead: status.ahead,
      behind: status.behind,
      isDirty: !status.isClean(),
    };
  } catch {
    return {
      worktree,
      modified: 0,
      staged: 0,
      untracked: 0,
      ahead: 0,
      behind: 0,
      isDirty: false,
    };
  }
}

export async function getMainBranch(cwd?: string): Promise<string> {
  const git = await getGit(cwd);
  try {
    // Check for origin/main or origin/master
    const remoteRefs = await git.raw(["branch", "-r"]);
    if (remoteRefs.includes("origin/main")) return "main";
    if (remoteRefs.includes("origin/master")) return "master";
  } catch {
    // Fall through
  }

  // Check local branches
  try {
    const branches = await git.branchLocal();
    if (branches.all.includes("main")) return "main";
    if (branches.all.includes("master")) return "master";
  } catch {
    // Fall through
  }

  return "main";
}

export async function createWorktree(
  repoRoot: string,
  path: string,
  branch: string,
  baseBranch?: string
): Promise<void> {
  const git = await getGit(repoRoot);
  const args = ["worktree", "add", "-b", branch, path];
  if (baseBranch) {
    args.push(baseBranch);
  }
  await git.raw(args);
}

export async function createWorktreeFromExisting(
  repoRoot: string,
  path: string,
  branch: string
): Promise<void> {
  const git = await getGit(repoRoot);
  await git.raw(["worktree", "add", path, branch]);
}

export async function removeWorktree(
  repoRoot: string,
  path: string,
  force = false
): Promise<void> {
  const git = await getGit(repoRoot);
  const args = ["worktree", "remove", path];
  if (force) args.push("--force");
  await git.raw(args);
}

export async function getTrackedFiles(cwd: string): Promise<string[]> {
  const git = await getGit(cwd);
  const result = await git.raw(["ls-files"]);
  return result.split("\n").filter(Boolean);
}

export async function getDiffFiles(
  worktreePath: string,
  baseBranch: string
): Promise<string[]> {
  const git = await getGit(worktreePath);
  const files = new Set<string>();

  // Committed changes vs base branch
  try {
    const committed = await git.raw([
      "diff",
      "--name-only",
      `${baseBranch}...HEAD`,
    ]);
    for (const f of committed.split("\n").filter(Boolean)) files.add(f);
  } catch {
    try {
      const committed = await git.raw([
        "diff",
        "--name-only",
        baseBranch,
      ]);
      for (const f of committed.split("\n").filter(Boolean)) files.add(f);
    } catch {
      // No common ancestor or branch doesn't exist
    }
  }

  // Unstaged changes in working tree
  try {
    const unstaged = await git.raw(["diff", "--name-only"]);
    for (const f of unstaged.split("\n").filter(Boolean)) files.add(f);
  } catch {
    // ignore
  }

  // Staged changes
  try {
    const staged = await git.raw(["diff", "--name-only", "--cached"]);
    for (const f of staged.split("\n").filter(Boolean)) files.add(f);
  } catch {
    // ignore
  }

  return [...files];
}

export async function getExistingBranches(cwd?: string): Promise<string[]> {
  const git = await getGit(cwd);
  const branches = await git.branchLocal();
  return branches.all;
}
