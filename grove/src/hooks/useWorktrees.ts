import { useState, useEffect, useCallback } from "react";
import {
  listWorktrees,
  getWorktreeStatus,
  WorktreeInfo,
  WorktreeStatus,
} from "../lib/git.js";

export function useWorktrees(cwd?: string) {
  const [worktrees, setWorktrees] = useState<WorktreeStatus[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const trees = await listWorktrees(cwd);
      const statuses = await Promise.all(trees.map(getWorktreeStatus));
      setWorktrees(statuses);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to list worktrees");
    } finally {
      setLoading(false);
    }
  }, [cwd]);

  useEffect(() => {
    refresh();
  }, [refresh]);

  return { worktrees, loading, error, refresh };
}
