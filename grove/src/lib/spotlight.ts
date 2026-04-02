import * as chokidar from "chokidar";
import {
  copyFileSync,
  existsSync,
  mkdirSync,
  unlinkSync,
} from "node:fs";
import { dirname, join, relative } from "node:path";
import { simpleGit } from "simple-git";
import { getTrackedFiles, getDiffFiles, getMainBranch } from "./git.js";

export type SpotlightSession = {
  worktreePath: string;
  mainWorktreePath: string;
  baseBranch: string;
  stashCommit: string | null;
  watcher: chokidar.FSWatcher | null;
  syncedFiles: Set<string>;
}

let activeSession: SpotlightSession | null = null;

export function getActiveSpotlight(): SpotlightSession | null {
  return activeSession;
}

/**
 * Snapshot the current dirty state of mainPath using `git stash create`.
 * Unlike `git stash push`, this creates a stash commit object without
 * modifying the working tree or index — purely non-destructive.
 * Returns the stash commit SHA, or null if the tree was clean.
 */
async function snapshotDirtyState(
  mainPath: string
): Promise<string | null> {
  const git = simpleGit(mainPath);
  try {
    const sha = (await git.raw(["stash", "create"])).trim();
    return sha || null; // empty string means nothing to stash
  } catch {
    return null;
  }
}

function copyFileToMain(
  file: string,
  worktreePath: string,
  mainPath: string
): boolean {
  const src = join(worktreePath, file);
  const dest = join(mainPath, file);

  if (!existsSync(src)) return false;

  const destDir = dirname(dest);
  if (!existsSync(destDir)) {
    mkdirSync(destDir, { recursive: true });
  }

  try {
    copyFileSync(src, dest);
    return true;
  } catch {
    return false;
  }
}

function removeFileFromMain(file: string, mainPath: string): boolean {
  const dest = join(mainPath, file);
  if (!existsSync(dest)) return true;

  try {
    unlinkSync(dest);
    return true;
  } catch {
    return false;
  }
}

export async function startSpotlight(
  worktreePath: string,
  mainWorktreePath: string,
  onSync?: (file: string, action: "copy" | "remove") => void,
  onError?: (error: string) => void
): Promise<SpotlightSession> {
  if (activeSession) {
    throw new Error(
      "A spotlight session is already active. Stop it first before starting a new one."
    );
  }

  const baseBranch = await getMainBranch(mainWorktreePath);

  // Snapshot any dirty state on main before we start overwriting files
  const stashCommit = await snapshotDirtyState(mainWorktreePath);

  // Get the list of tracked files and files that differ from the base branch
  const trackedFiles = new Set(await getTrackedFiles(worktreePath));
  const changedFiles = await getDiffFiles(worktreePath, baseBranch);

  const syncedFiles = new Set<string>();

  // Initial sync: copy all changed tracked files
  for (const file of changedFiles) {
    if (trackedFiles.has(file)) {
      if (copyFileToMain(file, worktreePath, mainWorktreePath)) {
        syncedFiles.add(file);
        onSync?.(file, "copy");
      } else {
        onError?.(`Failed to sync: ${file}`);
      }
    }
  }

  // Watch for ongoing changes in the worktree
  const watcher = chokidar.watch(worktreePath, {
    ignored: [
      /[/\\]\.git[/\\]?/,
      /[/\\]node_modules[/\\]/,
    ],
    persistent: true,
    ignoreInitial: true,
  });

  watcher.on("change", (filePath: string) => {
    const rel = relative(worktreePath, filePath);
    if (trackedFiles.has(rel) || syncedFiles.has(rel)) {
      if (copyFileToMain(rel, worktreePath, mainWorktreePath)) {
        syncedFiles.add(rel);
        onSync?.(rel, "copy");
      }
    }
  });

  watcher.on("add", (filePath: string) => {
    const rel = relative(worktreePath, filePath);
    if (trackedFiles.has(rel) || syncedFiles.has(rel)) {
      if (copyFileToMain(rel, worktreePath, mainWorktreePath)) {
        syncedFiles.add(rel);
        onSync?.(rel, "copy");
      }
    }
  });

  watcher.on("unlink", (filePath: string) => {
    const rel = relative(worktreePath, filePath);
    if (syncedFiles.has(rel)) {
      removeFileFromMain(rel, mainWorktreePath);
      syncedFiles.delete(rel);
      onSync?.(rel, "remove");
    }
  });

  watcher.on("error", (error: unknown) => {
    const msg = error instanceof Error ? error.message : String(error);
    onError?.(`Watcher error: ${msg}`);
  });

  const session: SpotlightSession = {
    worktreePath,
    mainWorktreePath,
    baseBranch,
    stashCommit,
    watcher,
    syncedFiles,
  };

  activeSession = session;
  return session;
}

export async function stopSpotlight(): Promise<{
  restoredFiles: string[];
}> {
  if (!activeSession) {
    throw new Error("No active spotlight session.");
  }

  const { watcher, syncedFiles, mainWorktreePath, stashCommit } =
    activeSession;

  // Stop watching
  if (watcher) {
    await watcher.close();
  }

  // Restore synced files: revert each one to its HEAD version
  const git = simpleGit(mainWorktreePath);
  const restoredFiles: string[] = [];

  for (const file of syncedFiles) {
    try {
      await git.raw(["checkout", "HEAD", "--", file]);
      restoredFiles.push(file);
    } catch {
      // File may not exist in HEAD (was new in worktree), just remove it
      removeFileFromMain(file, mainWorktreePath);
      restoredFiles.push(file);
    }
  }

  // If main had dirty state before spotlight, reapply it
  if (stashCommit) {
    try {
      await git.raw(["stash", "apply", stashCommit]);
    } catch {
      // Stash apply may conflict — leave files as-is, user can resolve
    }
  }

  activeSession = null;

  return { restoredFiles };
}
