import React from "react";
import { Box, Text, useInput } from "ink";
import { WorktreeStatus } from "../lib/git.js";

type Props = {
  worktree: WorktreeStatus;
  onConfirm: (force: boolean) => void;
  onCancel: () => void;
}

export function ConfirmDelete({ worktree, onConfirm, onCancel }: Props) {
  useInput((input, key) => {
    if (input === "y" || input === "Y") {
      onConfirm(false);
    }
    if (input === "f" || input === "F") {
      onConfirm(true);
    }
    if (input === "n" || input === "N" || key.escape) {
      onCancel();
    }
  });

  return (
    <Box flexDirection="column" paddingX={1} marginY={1}>
      <Text bold color="red">
        Delete worktree
      </Text>
      <Box marginTop={1} flexDirection="column">
        <Text>
          Branch: <Text bold>{worktree.worktree.branch}</Text>
        </Text>
        <Text>
          Path: <Text dimColor>{worktree.worktree.path}</Text>
        </Text>
        {worktree.isDirty && (
          <Text color="yellow">
            Warning: this worktree has uncommitted changes!
          </Text>
        )}
      </Box>
      <Box marginTop={1}>
        <Text>
          <Text color="green" bold>
            y
          </Text>
          <Text> confirm</Text>
          {"  "}
          {worktree.isDirty && (
            <>
              <Text color="red" bold>
                f
              </Text>
              <Text> force delete</Text>
              {"  "}
            </>
          )}
          <Text color="gray" bold>
            n
          </Text>
          <Text> cancel</Text>
        </Text>
      </Box>
    </Box>
  );
}
