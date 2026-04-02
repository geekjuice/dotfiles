import React, { useState } from "react";
import { Box, Text, useInput } from "ink";
import TextInput from "ink-text-input";

type Props = {
  repoName: string;
  existingBranches: string[];
  onSubmit: (branchName: string, baseBranch?: string) => void;
  onCancel: () => void;
}

type Step = "branch-name" | "base-branch";

export function CreateWorktree({
  repoName,
  existingBranches,
  onSubmit,
  onCancel,
}: Props) {
  const [step, setStep] = useState<Step>("branch-name");
  const [branchName, setBranchName] = useState("");
  const [baseBranch, setBaseBranch] = useState("");
  const [error, setError] = useState<string | null>(null);

  useInput((input, key) => {
    if (key.escape) {
      onCancel();
    }
  });

  const handleBranchSubmit = (value: string) => {
    const trimmed = value.trim();
    if (!trimmed) {
      setError("Branch name is required");
      return;
    }
    if (existingBranches.includes(trimmed)) {
      setError(`Branch '${trimmed}' already exists`);
      return;
    }
    setBranchName(trimmed);
    setError(null);
    setStep("base-branch");
  };

  const handleBaseSubmit = (value: string) => {
    const trimmed = value.trim();
    onSubmit(branchName, trimmed || undefined);
  };

  return (
    <Box flexDirection="column" paddingX={1} marginY={1}>
      <Text bold color="green">
        Create new worktree
      </Text>

      {step === "branch-name" && (
        <Box flexDirection="column" marginTop={1}>
          <Text>Branch name:</Text>
          <Box>
            <Text color="cyan">&gt; </Text>
            <TextInput
              value={branchName}
              onChange={setBranchName}
              onSubmit={handleBranchSubmit}
            />
          </Box>
          {error && <Text color="red">{error}</Text>}
          <Text dimColor>Press Escape to cancel</Text>
        </Box>
      )}

      {step === "base-branch" && (
        <Box flexDirection="column" marginTop={1}>
          <Text>
            Base branch <Text dimColor>(leave empty for default)</Text>:
          </Text>
          <Box>
            <Text color="cyan">&gt; </Text>
            <TextInput
              value={baseBranch}
              onChange={setBaseBranch}
              onSubmit={handleBaseSubmit}
            />
          </Box>
          <Text dimColor>Press Escape to cancel</Text>
        </Box>
      )}
    </Box>
  );
}
