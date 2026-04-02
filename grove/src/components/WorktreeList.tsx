import React from "react";
import { Box, Text, useInput } from "ink";
import { WorktreeStatus } from "../lib/git.js";
import { SessionInfo, formatSessionAge } from "../lib/sessions.js";

type Props = {
  worktrees: WorktreeStatus[];
  sessions: Map<string, SessionInfo | null>; // worktree path → most recent session
  selectedIndex: number;
  onSelect: (index: number) => void;
  onAction: (action: string, worktree: WorktreeStatus) => void;
  isActive: boolean;
  maxVisible?: number;
}

function StatusIndicator({ status }: { status: WorktreeStatus }) {
  if (status.worktree.isMain) {
    return <Text color="blue">*</Text>;
  }
  if (status.isDirty) {
    return <Text color="yellow">~</Text>;
  }
  return <Text color="green">+</Text>;
}

export function WorktreeList({
  worktrees,
  sessions,
  selectedIndex,
  onSelect,
  onAction,
  isActive,
  maxVisible = 20,
}: Props) {
  useInput(
    (input, key) => {
      if (key.upArrow || input === "k") {
        onSelect(Math.max(0, selectedIndex - 1));
      }
      if (key.downArrow || input === "j") {
        onSelect(Math.min(worktrees.length - 1, selectedIndex + 1));
      }
      if (key.return) {
        const wt = worktrees[selectedIndex];
        if (wt) onAction("open", wt);
      }
      if (input === "d") {
        const wt = worktrees[selectedIndex];
        if (wt && !wt.worktree.isMain) onAction("delete", wt);
      }
      if (input === "s") {
        const wt = worktrees[selectedIndex];
        if (wt && !wt.worktree.isMain) onAction("spotlight", wt);
      }
      if (input === "c") {
        const wt = worktrees[selectedIndex];
        if (wt) onAction("claude-new", wt);
      }
      if (input === "C") {
        const wt = worktrees[selectedIndex];
        if (wt) onAction("claude-continue", wt);
      }
      if (input === "R") {
        const wt = worktrees[selectedIndex];
        if (wt) onAction("claude-resume", wt);
      }
    },
    { isActive }
  );

  if (worktrees.length === 0) {
    return (
      <Text dimColor>No worktrees found. Press 'n' to create one.</Text>
    );
  }

  // Handle scrolling when list is longer than visible area
  const scrollOffset = Math.max(
    0,
    Math.min(
      selectedIndex - Math.floor(maxVisible / 2),
      worktrees.length - maxVisible
    )
  );
  const visible = worktrees.slice(scrollOffset, scrollOffset + maxVisible);

  return (
    <Box flexDirection="column">
      {visible.map((wt, i) => {
        const realIndex = i + scrollOffset;
        const isSelected = realIndex === selectedIndex;
        const session = sessions.get(wt.worktree.path);

        return (
          <Box key={wt.worktree.path}>
            <Text
              color={
                isSelected && isActive
                  ? "green"
                  : isSelected
                    ? "white"
                    : undefined
              }
              bold={isSelected}
              inverse={isSelected && isActive}
            >
              {" "}
              <StatusIndicator status={wt} />
              {" "}
              {wt.worktree.branch}
              {wt.isDirty ? (
                <Text
                  color={isSelected && isActive ? undefined : "yellow"}
                >
                  {" "}
                  {wt.staged > 0 && `+${wt.staged}`}
                  {wt.modified > 0 && ` ~${wt.modified}`}
                  {wt.untracked > 0 && ` ?${wt.untracked}`}
                </Text>
              ) : null}
              {(wt.ahead > 0 || wt.behind > 0) && (
                <Text
                  color={isSelected && isActive ? undefined : "cyan"}
                >
                  {wt.ahead > 0 ? ` ↑${wt.ahead}` : ""}
                  {wt.behind > 0 ? ` ↓${wt.behind}` : ""}
                </Text>
              )}
              {session && (
                <Text
                  color={isSelected && isActive ? undefined : "magenta"}
                >
                  {" "}
                  {formatSessionAge(session.lastActivity)}
                </Text>
              )}
              {" "}
            </Text>
          </Box>
        );
      })}
      {worktrees.length > maxVisible && (
        <Text dimColor>
          {" "}[{scrollOffset + 1}-
          {Math.min(scrollOffset + maxVisible, worktrees.length)}/
          {worktrees.length}]
        </Text>
      )}
    </Box>
  );
}
