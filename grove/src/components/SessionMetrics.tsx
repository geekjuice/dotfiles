import React from "react";
import { Box, Text } from "ink";
import {
  SessionInfo,
  SessionMetrics as Metrics,
  formatDuration,
  formatTokens,
  formatCost,
  sparkline,
  aggregateMetrics,
} from "../lib/sessions.js";

type Props = {
  sessions: SessionInfo[];
}

function BarInline({
  value,
  max,
  width = 12,
  color = "green",
}: {
  value: number;
  max: number;
  width?: number;
  color?: string;
}) {
  const filled = max > 0 ? Math.round((value / max) * width) : 0;
  const empty = width - filled;
  return (
    <Text>
      <Text color={color}>{"█".repeat(filled)}</Text>
      <Text dimColor>{"░".repeat(empty)}</Text>
    </Text>
  );
}

function MetricRow({
  label,
  value,
  color,
}: {
  label: string;
  value: string;
  color?: string;
}) {
  return (
    <Text>
      <Text dimColor>{label.padEnd(10)}</Text>
      <Text color={color} bold>
        {value}
      </Text>
    </Text>
  );
}

export function SessionMetricsView({ sessions }: Props) {
  if (sessions.length === 0) {
    return null;
  }

  const latest = sessions[0]!;
  const allMetrics = aggregateMetrics(sessions);

  // Build sparkline data from session costs (most recent on right)
  const costSpark = sessions
    .slice(0, 10)
    .reverse()
    .map((s) => s.metrics.estimatedCostUsd);
  const tokenSpark = sessions
    .slice(0, 10)
    .reverse()
    .map((s) => s.metrics.inputTokens + s.metrics.outputTokens);

  const maxTokensInSession = Math.max(
    ...sessions.map((s) => s.metrics.inputTokens + s.metrics.outputTokens)
  );

  return (
    <Box flexDirection="column">
      <Text bold dimColor>
        Session metrics:
      </Text>

      {/* Latest session stats */}
      <Box flexDirection="column">
        <MetricRow
          label="Cost"
          value={formatCost(latest.metrics.estimatedCostUsd)}
          color="yellow"
        />
        <MetricRow
          label="Duration"
          value={formatDuration(latest.metrics.durationMs)}
        />
        <MetricRow
          label="Tokens"
          value={`${formatTokens(latest.metrics.inputTokens)} in / ${formatTokens(latest.metrics.outputTokens)} out`}
        />
        <MetricRow
          label="Tools"
          value={`${latest.metrics.toolUseCount}`}
          color="cyan"
        />
        <MetricRow
          label="Turns"
          value={`${latest.metrics.userTurns} user / ${latest.metrics.assistantTurns} assistant`}
        />
      </Box>

      {/* Sparklines for trends across sessions */}
      {sessions.length > 1 && (
        <Box flexDirection="column" marginTop={1}>
          <Text bold dimColor>
            Trends ({sessions.length} sessions):
          </Text>
          <Text>
            <Text dimColor>{"Cost    "}</Text>
            <Text color="yellow">{sparkline(costSpark)}</Text>
            <Text dimColor> {formatCost(allMetrics.estimatedCostUsd)} total</Text>
          </Text>
          <Text>
            <Text dimColor>{"Tokens  "}</Text>
            <Text color="cyan">{sparkline(tokenSpark)}</Text>
            <Text dimColor>
              {" "}
              {formatTokens(allMetrics.inputTokens + allMetrics.outputTokens)}{" "}
              total
            </Text>
          </Text>

          {/* Per-session bar chart (most recent 5) */}
          {sessions.slice(0, 5).map((s) => {
            const total =
              s.metrics.inputTokens + s.metrics.outputTokens;
            return (
              <Box key={s.sessionId}>
                <Text dimColor>
                  {(s.slug || s.sessionId.slice(0, 8)).slice(0, 8).padEnd(9)}
                </Text>
                <BarInline
                  value={total}
                  max={maxTokensInSession}
                  width={10}
                  color="cyan"
                />
                <Text dimColor> {formatCost(s.metrics.estimatedCostUsd)}</Text>
              </Box>
            );
          })}
        </Box>
      )}
    </Box>
  );
}
