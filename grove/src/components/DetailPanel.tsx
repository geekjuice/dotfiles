import React, { useState, useEffect } from "react";
import { Box, Text } from "ink";
import { WorktreeStatus } from "../lib/git.js";
import { getActiveSpotlight } from "../lib/spotlight.js";
import {
  SessionInfo,
  findSessionsForWorktree,
  formatSessionAge,
  formatCost,
} from "../lib/sessions.js";
import { SessionMetricsView } from "./SessionMetrics.js";
import { simpleGit } from "simple-git";

type Props = {
  worktree: WorktreeStatus | null;
}

export function DetailPanel({ worktree }: Props) {
  const [recentCommits, setRecentCommits] = useState<string[]>([]);
  const [changedFiles, setChangedFiles] = useState<string[]>([]);
  const [sessions, setSessions] = useState<SessionInfo[]>([]);
  const spotlight = getActiveSpotlight();

  useEffect(() => {
    if (!worktree) return;

    const load = async () => {
      try {
        const git = simpleGit(worktree.worktree.path);

        const log = await git.log({ maxCount: 5, "--oneline": null } as any);
        setRecentCommits(
          log.all.map((c) => `${c.hash.slice(0, 7)} ${c.message}`)
        );

        if (worktree.isDirty) {
          const status = await git.status();
          const files = [
            ...status.staged.map((f) => `S ${f}`),
            ...status.modified.map((f) => `M ${f}`),
            ...status.not_added.map((f) => `? ${f}`),
            ...status.deleted.map((f) => `D ${f}`),
          ];
          setChangedFiles(files.slice(0, 10));
        } else {
          setChangedFiles([]);
        }
      } catch {
        setRecentCommits([]);
        setChangedFiles([]);
      }

      // Load Claude sessions for this worktree
      try {
        const found = findSessionsForWorktree(worktree.worktree.path);
        setSessions(found.slice(0, 10));
      } catch {
        setSessions([]);
      }
    };

    load();
  }, [worktree]);

  if (!worktree) {
    return <Text dimColor>Select a worktree to view details</Text>;
  }

  const isSpotlighted =
    spotlight?.worktreePath === worktree.worktree.path;

  return (
    <Box flexDirection="column">
      {/* Worktree info */}
      <Box flexDirection="column">
        <Text>
          <Text dimColor>Branch: </Text>
          <Text bold color="green">
            {worktree.worktree.branch}
          </Text>
          {isSpotlighted && (
            <Text color="magenta" bold>
              {" "}
              SPOTLIGHT
            </Text>
          )}
        </Text>
        <Text>
          <Text dimColor>Path:   </Text>
          <Text>{worktree.worktree.path}</Text>
        </Text>
        <Text>
          <Text dimColor>Status: </Text>
          {worktree.isDirty ? (
            <Text color="yellow">dirty</Text>
          ) : (
            <Text color="green">clean</Text>
          )}
          {worktree.worktree.isMain && <Text color="blue"> (main)</Text>}
        </Text>
        <Text>
          <Text dimColor>HEAD:   </Text>
          <Text>{worktree.worktree.head.slice(0, 10)}</Text>
        </Text>
      </Box>

      {/* Claude sessions list */}
      <Box flexDirection="column" marginTop={1}>
        <Text bold dimColor>
          Claude sessions:
        </Text>
        {sessions.length === 0 ? (
          <Text dimColor>  No sessions. Press 'c' to start one.</Text>
        ) : (
          sessions.slice(0, 3).map((s, i) => (
            <Text key={s.sessionId}>
              <Text color={i === 0 ? "magenta" : "gray"}>
                {i === 0 ? "▸ " : "  "}
              </Text>
              <Text color={i === 0 ? "white" : undefined} bold={i === 0}>
                {s.slug}
              </Text>
              <Text dimColor> {formatSessionAge(s.lastActivity)}</Text>
              <Text color="yellow"> {formatCost(s.metrics.estimatedCostUsd)}</Text>
            </Text>
          ))
        )}
      </Box>

      {/* Session metrics with sparklines and bar charts */}
      {sessions.length > 0 && (
        <Box flexDirection="column" marginTop={1}>
          <SessionMetricsView sessions={sessions} />
        </Box>
      )}

      {/* Changed files */}
      {changedFiles.length > 0 && (
        <Box flexDirection="column" marginTop={1}>
          <Text bold dimColor>
            Changed files:
          </Text>
          {changedFiles.map((f, i) => {
            const type = f[0];
            const color =
              type === "S"
                ? "green"
                : type === "M"
                  ? "yellow"
                  : type === "D"
                    ? "red"
                    : "gray";
            return (
              <Text key={i}>
                <Text color={color}>{f.slice(0, 2)}</Text>
                <Text>{f.slice(2)}</Text>
              </Text>
            );
          })}
        </Box>
      )}

      {/* Recent commits */}
      {recentCommits.length > 0 && (
        <Box flexDirection="column" marginTop={1}>
          <Text bold dimColor>
            Recent commits:
          </Text>
          {recentCommits.map((c, i) => (
            <Text key={i}>
              <Text color="yellow">{c.slice(0, 7)}</Text>
              <Text>{c.slice(7)}</Text>
            </Text>
          ))}
        </Box>
      )}
    </Box>
  );
}
