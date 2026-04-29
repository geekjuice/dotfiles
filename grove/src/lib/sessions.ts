import { readdirSync, readFileSync, existsSync } from "node:fs";
import { join, resolve } from "node:path";
import { homedir } from "node:os";
import { spawnSync } from "node:child_process";
import { randomUUID } from "node:crypto";

export type SessionMetrics = {
  inputTokens: number;
  outputTokens: number;
  cacheReadTokens: number;
  cacheCreateTokens: number;
  toolUseCount: number;
  userTurns: number;
  assistantTurns: number;
  estimatedCostUsd: number;
  durationMs: number;
}

export type SessionInfo = {
  sessionId: string;
  slug: string;
  lastActivity: Date;
  firstActivity: Date;
  gitBranch: string;
  cwd: string;
  messageCount: number;
  metrics: SessionMetrics;
}

function getClaudeProjectsDir(): string {
  return join(homedir(), ".claude", "projects");
}

function manglePath(dirPath: string): string {
  // Claude Code mangles paths: /home/user/foo → -home-user-foo
  return dirPath.replace(/\//g, "-").replace(/^-/, "-");
}

// Claude API pricing (per million tokens) - approximate for Opus/Sonnet
const PRICE_INPUT_PER_M = 15; // $15/M input tokens
const PRICE_OUTPUT_PER_M = 75; // $75/M output tokens
const PRICE_CACHE_READ_PER_M = 1.5; // $1.50/M cache read tokens
const PRICE_CACHE_CREATE_PER_M = 18.75; // $18.75/M cache creation tokens

function estimateCost(metrics: SessionMetrics): number {
  return (
    (metrics.inputTokens / 1_000_000) * PRICE_INPUT_PER_M +
    (metrics.outputTokens / 1_000_000) * PRICE_OUTPUT_PER_M +
    (metrics.cacheReadTokens / 1_000_000) * PRICE_CACHE_READ_PER_M +
    (metrics.cacheCreateTokens / 1_000_000) * PRICE_CACHE_CREATE_PER_M
  );
}

function parseSessionFile(filePath: string): SessionInfo | null {
  try {
    const content = readFileSync(filePath, "utf-8");
    const lines = content.trim().split("\n").filter(Boolean);
    if (lines.length === 0) return null;

    let sessionId = "";
    let slug = "";
    let firstActivity = new Date(8640000000000000); // far future
    let lastActivity = new Date(0);
    let gitBranch = "";
    let cwd = "";
    let messageCount = 0;

    const metrics: SessionMetrics = {
      inputTokens: 0,
      outputTokens: 0,
      cacheReadTokens: 0,
      cacheCreateTokens: 0,
      toolUseCount: 0,
      userTurns: 0,
      assistantTurns: 0,
      estimatedCostUsd: 0,
      durationMs: 0,
    };

    // Parse all lines for accurate metrics
    for (const line of lines) {
      try {
        const data = JSON.parse(line);
        if (data.sessionId && !sessionId) sessionId = data.sessionId;
        if (data.slug) slug = data.slug;
        if (data.gitBranch) gitBranch = data.gitBranch;
        if (data.cwd) cwd = data.cwd;

        if (data.timestamp) {
          const ts = new Date(data.timestamp);
          if (ts > lastActivity) lastActivity = ts;
          if (ts < firstActivity) firstActivity = ts;
        }

        if (data.type === "user") {
          metrics.userTurns++;
          messageCount++;
        }
        if (data.type === "assistant") {
          metrics.assistantTurns++;
          messageCount++;

          // Extract token usage from assistant messages
          const usage = data.message?.usage;
          if (usage) {
            metrics.inputTokens += usage.input_tokens || 0;
            metrics.outputTokens += usage.output_tokens || 0;
            metrics.cacheReadTokens +=
              usage.cache_read_input_tokens || 0;
            metrics.cacheCreateTokens +=
              usage.cache_creation_input_tokens || 0;
          }

          // Count tool uses in assistant content
          const content = data.message?.content;
          if (Array.isArray(content)) {
            for (const block of content) {
              if (block.type === "tool_use") {
                metrics.toolUseCount++;
              }
            }
          }
        }
      } catch {
        // Skip unparseable lines
      }
    }

    if (!sessionId) return null;

    // Calculate duration and cost
    if (lastActivity > firstActivity) {
      metrics.durationMs =
        lastActivity.getTime() - firstActivity.getTime();
    }
    metrics.estimatedCostUsd = estimateCost(metrics);

    return {
      sessionId,
      slug: slug || sessionId.slice(0, 8),
      firstActivity:
        firstActivity.getTime() < 8640000000000000
          ? firstActivity
          : lastActivity,
      lastActivity,
      gitBranch,
      cwd,
      messageCount,
      metrics,
    };
  } catch {
    return null;
  }
}

export function findSessionsForWorktree(
  worktreePath: string
): SessionInfo[] {
  const projectsDir = getClaudeProjectsDir();
  if (!existsSync(projectsDir)) return [];

  // Try the mangled path for this worktree
  const mangled = manglePath(worktreePath);
  const projectDir = join(projectsDir, mangled);

  if (!existsSync(projectDir)) return [];

  const sessions: SessionInfo[] = [];

  try {
    const entries = readdirSync(projectDir);
    for (const entry of entries) {
      if (!entry.endsWith(".jsonl")) continue;
      const filePath = join(projectDir, entry);
      const session = parseSessionFile(filePath);
      if (session) {
        sessions.push(session);
      }
    }
  } catch {
    return [];
  }

  // Sort by most recent first
  sessions.sort(
    (a, b) => b.lastActivity.getTime() - a.lastActivity.getTime()
  );

  return sessions;
}

export function findSessionsForBranch(
  worktreePath: string,
  branch: string
): SessionInfo[] {
  const all = findSessionsForWorktree(worktreePath);
  return all.filter((s) => s.gitBranch === branch);
}

export type LaunchResult = {
  sessionId: string;
  exitCode: number;
}

export function launchClaudeSession(
  worktreePath: string,
  options?: {
    continue?: boolean;
    resume?: string;
    sessionId?: string;
    name?: string;
    prompt?: string;
  }
): LaunchResult {
  const args: string[] = [];
  let sessionId = options?.sessionId || "";

  if (options?.resume) {
    args.push("--resume", options.resume);
  } else if (options?.continue) {
    args.push("--continue");
  } else {
    // New session - pre-generate an ID so we can track it
    sessionId = sessionId || randomUUID();
    args.push("--session-id", sessionId);
  }

  if (options?.name) {
    args.push("--name", options.name);
  }

  if (options?.prompt) {
    args.push(options.prompt);
  }

  const result = spawnSync("claude", args, {
    cwd: worktreePath,
    stdio: "inherit",
    env: { ...process.env },
  });

  return {
    sessionId,
    exitCode: result.status ?? 1,
  };
}

export function getRecentSession(
  worktreePath: string
): SessionInfo | null {
  const sessions = findSessionsForWorktree(worktreePath);
  return sessions[0] ?? null;
}

export function formatSessionAge(date: Date): string {
  const now = Date.now();
  const diff = now - date.getTime();
  const mins = Math.floor(diff / 60000);
  const hours = Math.floor(diff / 3600000);
  const days = Math.floor(diff / 86400000);

  if (mins < 1) return "just now";
  if (mins < 60) return `${mins}m ago`;
  if (hours < 24) return `${hours}h ago`;
  return `${days}d ago`;
}

export function formatDuration(ms: number): string {
  if (ms < 60000) return `${Math.round(ms / 1000)}s`;
  const mins = Math.floor(ms / 60000);
  if (mins < 60) return `${mins}m`;
  const hours = Math.floor(mins / 60);
  const remMins = mins % 60;
  return remMins > 0 ? `${hours}h ${remMins}m` : `${hours}h`;
}

export function formatTokens(n: number): string {
  if (n < 1000) return `${n}`;
  if (n < 1_000_000) return `${(n / 1000).toFixed(1)}k`;
  return `${(n / 1_000_000).toFixed(2)}M`;
}

export function formatCost(usd: number): string {
  if (usd < 0.01) return "<$0.01";
  return `$${usd.toFixed(2)}`;
}

/** Build a sparkline string from an array of numbers using Unicode blocks */
export function sparkline(values: number[]): string {
  if (values.length === 0) return "";
  const blocks = " ▁▂▃▄▅▆▇█";
  const max = Math.max(...values);
  if (max === 0) return blocks[0]!.repeat(values.length);
  return values
    .map((v) => {
      const idx = Math.round((v / max) * 8);
      return blocks[idx] || blocks[0];
    })
    .join("");
}

/** Aggregate metrics across multiple sessions */
export function aggregateMetrics(sessions: SessionInfo[]): SessionMetrics {
  const agg: SessionMetrics = {
    inputTokens: 0,
    outputTokens: 0,
    cacheReadTokens: 0,
    cacheCreateTokens: 0,
    toolUseCount: 0,
    userTurns: 0,
    assistantTurns: 0,
    estimatedCostUsd: 0,
    durationMs: 0,
  };
  for (const s of sessions) {
    agg.inputTokens += s.metrics.inputTokens;
    agg.outputTokens += s.metrics.outputTokens;
    agg.cacheReadTokens += s.metrics.cacheReadTokens;
    agg.cacheCreateTokens += s.metrics.cacheCreateTokens;
    agg.toolUseCount += s.metrics.toolUseCount;
    agg.userTurns += s.metrics.userTurns;
    agg.assistantTurns += s.metrics.assistantTurns;
    agg.estimatedCostUsd += s.metrics.estimatedCostUsd;
    agg.durationMs += s.metrics.durationMs;
  }
  return agg;
}
