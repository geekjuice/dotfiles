import React, { useState, useCallback, useEffect } from "react";
import { Box, Text, useApp, useInput } from "ink";
import Spinner from "ink-spinner";
import { Panel } from "./Panel.js";
import { WorktreeList } from "./WorktreeList.js";
import { DetailPanel } from "./DetailPanel.js";
import { ActivityLog } from "./ActivityLog.js";
import { CreateWorktree } from "./CreateWorktree.js";
import { ConfirmDelete } from "./ConfirmDelete.js";
import { useWorktrees } from "../hooks/useWorktrees.js";
import { useTerminalSize } from "../hooks/useTerminalSize.js";
import { useActivityLog } from "../hooks/useActivityLog.js";
import {
  getRepoName,
  getRepoRoot,
  createWorktree,
  removeWorktree,
  getExistingBranches,
  WorktreeStatus,
} from "../lib/git.js";
import { loadConfig, resolveWorktreePath } from "../lib/config.js";
import {
  startSpotlight,
  stopSpotlight,
  getActiveSpotlight,
} from "../lib/spotlight.js";
import {
  launchClaudeSession,
  getRecentSession,
  SessionInfo,
} from "../lib/sessions.js";
import { spawnSync } from "node:child_process";

// Alternate screen escape sequences - used when suspending TUI
const ENTER_ALT = "\x1b[?1049h";
const EXIT_ALT = "\x1b[?1049l";
const HIDE_CURSOR = "\x1b[?25l";
const SHOW_CURSOR = "\x1b[?25h";

type View = "list" | "create" | "delete" | "spotlight-confirm";

type Props = {
  cwd?: string;
}

export function App({ cwd }: Props) {
  const [view, setView] = useState<View>("list");
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [deleteTarget, setDeleteTarget] = useState<WorktreeStatus | null>(null);
  const [spotlightTarget, setSpotlightTarget] =
    useState<WorktreeStatus | null>(null);
  const [existingBranches, setExistingBranches] = useState<string[]>([]);
  const [repoName, setRepoName] = useState("");
  const [repoRoot, setRepoRoot] = useState("");
  const [spotlightActive, setSpotlightActive] = useState(false);
  const [sessions, setSessions] = useState<Map<string, SessionInfo | null>>(
    new Map()
  );

  const { worktrees, loading, error, refresh } = useWorktrees(cwd);
  const { exit } = useApp();
  const { columns, rows } = useTerminalSize();
  const { entries, log } = useActivityLog();
  const config = loadConfig();

  // Initialize repo info
  useEffect(() => {
    (async () => {
      try {
        const root = await getRepoRoot(cwd);
        setRepoRoot(root);
        setRepoName(getRepoName(root));
        log("Grove started", "info");
      } catch {
        setRepoName("unknown");
        log("Could not detect repository", "error");
      }
    })();
  }, [cwd]);

  // Load session info for all worktrees
  const refreshSessions = useCallback(() => {
    const map = new Map<string, SessionInfo | null>();
    for (const wt of worktrees) {
      map.set(wt.worktree.path, getRecentSession(wt.worktree.path));
    }
    setSessions(map);
  }, [worktrees]);

  useEffect(() => {
    refreshSessions();
  }, [refreshSessions]);

  const selectedWorktree = worktrees[selectedIndex] ?? null;

  // Suspend TUI, run a process, resume TUI
  const suspendAndRun = useCallback(
    (fn: () => void) => {
      // Exit alternate screen so the spawned process gets a normal terminal
      process.stdout.write(SHOW_CURSOR + EXIT_ALT);
      try {
        fn();
      } finally {
        // Re-enter alternate screen
        process.stdout.write(ENTER_ALT + HIDE_CURSOR);
        refresh();
        refreshSessions();
      }
    },
    [refresh, refreshSessions]
  );

  const handleAction = useCallback(
    async (action: string, wt: WorktreeStatus) => {
      if (action === "open") {
        log(`Opening shell in ${wt.worktree.branch}`, "info");
        suspendAndRun(() => {
          const shell = process.env.SHELL || "/bin/bash";
          spawnSync(shell, {
            cwd: wt.worktree.path,
            stdio: "inherit",
            env: { ...process.env },
          });
        });
        log(`Returned from ${wt.worktree.branch}`, "info");
      } else if (action === "claude-new") {
        log(`Launching new Claude session in ${wt.worktree.branch}`, "info");
        suspendAndRun(() => {
          const result = launchClaudeSession(wt.worktree.path, {
            name: `grove: ${wt.worktree.branch}`,
          });
          log(
            `Claude session ended (${result.sessionId.slice(0, 8)})`,
            result.exitCode === 0 ? "success" : "info"
          );
        });
      } else if (action === "claude-continue") {
        const session = sessions.get(wt.worktree.path);
        if (session) {
          log(
            `Continuing Claude session "${session.slug}" in ${wt.worktree.branch}`,
            "info"
          );
          suspendAndRun(() => {
            const result = launchClaudeSession(wt.worktree.path, {
              continue: true,
            });
            log(
              `Claude session ended`,
              result.exitCode === 0 ? "success" : "info"
            );
          });
        } else {
          log(
            `No existing session for ${wt.worktree.branch}, starting new one`,
            "info"
          );
          suspendAndRun(() => {
            const result = launchClaudeSession(wt.worktree.path, {
              name: `grove: ${wt.worktree.branch}`,
            });
            log(
              `Claude session ended (${result.sessionId.slice(0, 8)})`,
              result.exitCode === 0 ? "success" : "info"
            );
          });
        }
      } else if (action === "claude-resume") {
        log(`Opening Claude resume picker in ${wt.worktree.branch}`, "info");
        suspendAndRun(() => {
          // --resume with no value opens the interactive picker
          launchClaudeSession(wt.worktree.path, {
            resume: "",
          });
          log("Claude resume picker closed", "info");
        });
      } else if (action === "delete") {
        setDeleteTarget(wt);
        setView("delete");
      } else if (action === "spotlight") {
        if (getActiveSpotlight()) {
          try {
            const result = await stopSpotlight();
            setSpotlightActive(false);
            log(
              `Spotlight stopped. Restored ${result.restoredFiles.length} files.`,
              "success"
            );
            refresh();
          } catch (e) {
            log(
              e instanceof Error ? e.message : "Failed to stop spotlight",
              "error"
            );
          }
        } else {
          setSpotlightTarget(wt);
          setView("spotlight-confirm");
        }
      }
    },
    [refresh, log, suspendAndRun, sessions]
  );

  const handleCreateSubmit = useCallback(
    async (branchName: string, baseBranch?: string) => {
      try {
        const path = resolveWorktreePath(config, repoName, branchName);
        await createWorktree(repoRoot, path, branchName, baseBranch);
        log(`Created worktree: ${branchName}`, "success");
        setView("list");
        refresh();
      } catch (e) {
        log(
          e instanceof Error ? e.message : "Failed to create worktree",
          "error"
        );
        setView("list");
      }
    },
    [config, repoName, repoRoot, refresh, log]
  );

  const handleDeleteConfirm = useCallback(
    async (force: boolean) => {
      if (!deleteTarget) return;
      try {
        await removeWorktree(repoRoot, deleteTarget.worktree.path, force);
        log(`Removed worktree: ${deleteTarget.worktree.branch}`, "success");
        setDeleteTarget(null);
        setView("list");
        setSelectedIndex((i) =>
          Math.max(0, Math.min(i, worktrees.length - 2))
        );
        refresh();
      } catch (e) {
        log(
          e instanceof Error ? e.message : "Failed to remove worktree",
          "error"
        );
        setView("list");
      }
    },
    [deleteTarget, repoRoot, refresh, log, worktrees.length]
  );

  const handleSpotlightConfirm = useCallback(async () => {
    if (!spotlightTarget) return;
    try {
      const mainWt = worktrees.find((w) => w.worktree.isMain);
      if (!mainWt) {
        log("No main worktree found", "error");
        setView("list");
        return;
      }

      await startSpotlight(
        spotlightTarget.worktree.path,
        mainWt.worktree.path,
        (file, action) => {
          log(
            `${action === "copy" ? "Synced" : "Removed"}: ${file}`,
            "spotlight"
          );
        },
        (err) => {
          log(err, "error");
        }
      );

      setSpotlightActive(true);
      log(
        `Spotlight active: ${spotlightTarget.worktree.branch} → main`,
        "spotlight"
      );
      setView("list");
    } catch (e) {
      log(
        e instanceof Error ? e.message : "Failed to start spotlight",
        "error"
      );
      setView("list");
    }
  }, [spotlightTarget, worktrees, log]);

  // Spotlight confirm key handling
  useInput(
    (input, key) => {
      if (input === "y" || input === "Y") {
        handleSpotlightConfirm();
      }
      if (input === "n" || input === "N" || key.escape) {
        setSpotlightTarget(null);
        setView("list");
      }
    },
    { isActive: view === "spotlight-confirm" }
  );

  // Global key handling for list view
  useInput(
    (input, key) => {
      if (input === "q") {
        if (getActiveSpotlight()) {
          stopSpotlight()
            .then(() => log("Spotlight stopped on exit", "info"))
            .finally(() => exit());
        } else {
          exit();
        }
      }
      if (input === "n") {
        getExistingBranches(cwd).then(setExistingBranches);
        setView("create");
      }
      if (input === "r") {
        refresh();
        refreshSessions();
        log("Refreshed", "info");
      }
    },
    { isActive: view === "list" }
  );

  if (loading && worktrees.length === 0) {
    return (
      <Box
        flexDirection="column"
        width={columns}
        height={rows}
        justifyContent="center"
        alignItems="center"
      >
        <Text color="green">
          <Spinner type="dots" />
        </Text>
        <Text> Loading worktrees...</Text>
      </Box>
    );
  }

  if (error) {
    return (
      <Box
        flexDirection="column"
        width={columns}
        height={rows}
        justifyContent="center"
        alignItems="center"
      >
        <Text color="red">Error: {error}</Text>
        <Text dimColor>Press q to quit</Text>
      </Box>
    );
  }

  // Calculate panel sizes
  const leftWidth = Math.max(30, Math.floor(columns * 0.35));
  const rightWidth = columns - leftWidth;
  const topHeight = rows - 12;
  const logHeight = 8;

  // Modal views overlay
  if (view === "create") {
    return (
      <Box flexDirection="column" width={columns} height={rows}>
        <TitleBar
          repoName={repoName}
          worktreeCount={worktrees.length}
          spotlightActive={spotlightActive}
          columns={columns}
        />
        <Box flexGrow={1} justifyContent="center" alignItems="center">
          <Box
            borderStyle="round"
            borderColor="green"
            flexDirection="column"
            width={Math.min(60, columns - 4)}
            padding={1}
          >
            <CreateWorktree
              repoName={repoName}
              existingBranches={existingBranches}
              onSubmit={handleCreateSubmit}
              onCancel={() => setView("list")}
            />
          </Box>
        </Box>
      </Box>
    );
  }

  if (view === "delete" && deleteTarget) {
    return (
      <Box flexDirection="column" width={columns} height={rows}>
        <TitleBar
          repoName={repoName}
          worktreeCount={worktrees.length}
          spotlightActive={spotlightActive}
          columns={columns}
        />
        <Box flexGrow={1} justifyContent="center" alignItems="center">
          <Box
            borderStyle="round"
            borderColor="red"
            flexDirection="column"
            width={Math.min(60, columns - 4)}
            padding={1}
          >
            <ConfirmDelete
              worktree={deleteTarget}
              onConfirm={handleDeleteConfirm}
              onCancel={() => {
                setDeleteTarget(null);
                setView("list");
              }}
            />
          </Box>
        </Box>
      </Box>
    );
  }

  if (view === "spotlight-confirm" && spotlightTarget) {
    return (
      <Box flexDirection="column" width={columns} height={rows}>
        <TitleBar
          repoName={repoName}
          worktreeCount={worktrees.length}
          spotlightActive={spotlightActive}
          columns={columns}
        />
        <Box flexGrow={1} justifyContent="center" alignItems="center">
          <Box
            borderStyle="round"
            borderColor="magenta"
            flexDirection="column"
            width={Math.min(60, columns - 4)}
            padding={1}
          >
            <Text bold color="magenta">
              Start Spotlight
            </Text>
            <Text>
              Sync changes from{" "}
              <Text bold>{spotlightTarget.worktree.branch}</Text> to main
              worktree?
            </Text>
            <Text dimColor>
              Files will be temporarily copied. Original state restored on stop.
            </Text>
            <Box marginTop={1} gap={2}>
              <Text>
                <Text color="green" bold>
                  y
                </Text>{" "}
                confirm
              </Text>
              <Text>
                <Text dimColor bold>
                  n
                </Text>{" "}
                cancel
              </Text>
            </Box>
          </Box>
        </Box>
      </Box>
    );
  }

  // Main dashboard layout
  return (
    <Box flexDirection="column" width={columns} height={rows}>
      <TitleBar
        repoName={repoName}
        worktreeCount={worktrees.length}
        spotlightActive={spotlightActive}
        columns={columns}
      />

      <Box height={topHeight}>
        <Panel
          title="Worktrees"
          width={leftWidth}
          height={topHeight}
          focused={view === "list"}
          badge={`${worktrees.length}`}
        >
          <WorktreeList
            worktrees={worktrees}
            sessions={sessions}
            selectedIndex={selectedIndex}
            onSelect={setSelectedIndex}
            onAction={handleAction}
            isActive={view === "list"}
            maxVisible={topHeight - 4}
          />
        </Panel>

        <Panel title="Details" width={rightWidth} height={topHeight}>
          <DetailPanel worktree={selectedWorktree} />
        </Panel>
      </Box>

      <Panel
        title="Activity"
        height={logHeight}
        badge={spotlightActive ? "SPOTLIGHT" : undefined}
        badgeColor="magenta"
      >
        <ActivityLog entries={entries} maxVisible={logHeight - 4} />
      </Panel>

      <HelpBarCompact spotlightActive={spotlightActive} />
    </Box>
  );
}

function TitleBar({
  repoName,
  worktreeCount,
  spotlightActive,
  columns,
}: {
  repoName: string;
  worktreeCount: number;
  spotlightActive: boolean;
  columns: number;
}) {
  return (
    <Box width={columns}>
      <Text bold color="green">
        {" "}
        grove{" "}
      </Text>
      <Text dimColor>| </Text>
      <Text bold>{repoName}</Text>
      <Text dimColor>
        {" "}
        ({worktreeCount} worktree{worktreeCount !== 1 ? "s" : ""})
      </Text>
      {spotlightActive && (
        <Text color="magenta" bold>
          {" "}
          <Spinner type="dots" /> SPOTLIGHT
        </Text>
      )}
    </Box>
  );
}

function HelpBarCompact({ spotlightActive }: { spotlightActive: boolean }) {
  return (
    <Box gap={1} flexWrap="wrap">
      <Text>
        <Text color="cyan" bold>
          {" "}
          j/k
        </Text>
        <Text dimColor> nav</Text>
      </Text>
      <Text>
        <Text color="cyan" bold>
          enter
        </Text>
        <Text dimColor> shell</Text>
      </Text>
      <Text>
        <Text color="cyan" bold>
          c
        </Text>
        <Text dimColor> claude</Text>
      </Text>
      <Text>
        <Text color="cyan" bold>
          C
        </Text>
        <Text dimColor> continue</Text>
      </Text>
      <Text>
        <Text color="cyan" bold>
          R
        </Text>
        <Text dimColor> resume</Text>
      </Text>
      <Text>
        <Text color="cyan" bold>
          n
        </Text>
        <Text dimColor> new</Text>
      </Text>
      <Text>
        <Text color="cyan" bold>
          d
        </Text>
        <Text dimColor> del</Text>
      </Text>
      <Text>
        <Text color="cyan" bold>
          s
        </Text>
        <Text dimColor> {spotlightActive ? "unstage" : "spotlight"}</Text>
      </Text>
      <Text>
        <Text color="cyan" bold>
          r
        </Text>
        <Text dimColor> refresh</Text>
      </Text>
      <Text>
        <Text color="cyan" bold>
          q
        </Text>
        <Text dimColor> quit</Text>
      </Text>
    </Box>
  );
}
