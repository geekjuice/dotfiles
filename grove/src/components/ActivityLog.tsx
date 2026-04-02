import React from "react";
import { Box, Text } from "ink";
import { LogEntry } from "../hooks/useActivityLog.js";

type Props = {
  entries: LogEntry[];
  maxVisible?: number;
}

const typeColors: Record<LogEntry["type"], string> = {
  info: "white",
  success: "green",
  error: "red",
  spotlight: "magenta",
};

function formatTime(date: Date): string {
  return date.toLocaleTimeString("en-US", {
    hour12: false,
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
}

export function ActivityLog({ entries, maxVisible = 6 }: Props) {
  const visible = entries.slice(-maxVisible);

  if (visible.length === 0) {
    return <Text dimColor>No activity yet</Text>;
  }

  return (
    <Box flexDirection="column">
      {visible.map((entry) => (
        <Text key={entry.id}>
          <Text dimColor>{formatTime(entry.timestamp)} </Text>
          <Text color={typeColors[entry.type]}>{entry.message}</Text>
        </Text>
      ))}
    </Box>
  );
}
