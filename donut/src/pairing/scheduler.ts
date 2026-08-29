import { Cron } from "croner";
import { eq } from "drizzle-orm";
import { db } from "../db/client";
import { channels, workspaces } from "../db/schema";
import { executePairingRound } from "../slack/commands";

// Active cron jobs keyed by channel config ID
const activeJobs = new Map<number, Cron>();

// Schedule a pairing round for a specific channel config
function scheduleChannel(config: {
  id: number;
  channelId: string;
  frequency: string;
  timezone: string;
  workspaceId: string;
}): void {
  // Cancel existing job if any
  const existing = activeJobs.get(config.id);
  if (existing) existing.stop();

  const job = new Cron(config.frequency, { timezone: config.timezone }, async () => {
    console.log(`[scheduler] Running pairing round for channel ${config.channelId}`);

    // Fetch fresh bot token
    const [workspace] = await db
      .select({ botToken: workspaces.botToken })
      .from(workspaces)
      .where(eq(workspaces.id, config.workspaceId))
      .limit(1);

    if (!workspace) {
      console.error(`[scheduler] No workspace found for ${config.workspaceId}`);
      return;
    }

    const result = await executePairingRound(config.id, config.channelId, workspace.botToken);
    if ("error" in result) {
      console.error(`[scheduler] Pairing failed for ${config.channelId}: ${result.error}`);
    } else {
      console.log(`[scheduler] Paired ${result.groupCount} groups in ${config.channelId}`);
    }
  });

  activeJobs.set(config.id, job);
  const next = job.nextRun();
  console.log(`[scheduler] Scheduled channel ${config.channelId} (${config.frequency} ${config.timezone}), next: ${next?.toISOString() ?? "unknown"}`);
}

// Load all active channel configs and schedule them
export async function startScheduler(): Promise<void> {
  const activeChannels = await db
    .select()
    .from(channels)
    .where(eq(channels.isActive, true));

  console.log(`[scheduler] Loading ${activeChannels.length} active channel(s)`);

  for (const config of activeChannels) {
    scheduleChannel({
      id: config.id,
      channelId: config.channelId,
      frequency: config.frequency,
      timezone: config.timezone,
      workspaceId: config.workspaceId,
    });
  }
}

// Reschedule a specific channel (call after config update)
export async function rescheduleChannel(channelConfigId: number): Promise<void> {
  const [config] = await db
    .select()
    .from(channels)
    .where(eq(channels.id, channelConfigId))
    .limit(1);

  if (!config || !config.isActive) {
    // Remove existing job if channel was deactivated
    const existing = activeJobs.get(channelConfigId);
    if (existing) {
      existing.stop();
      activeJobs.delete(channelConfigId);
    }
    return;
  }

  scheduleChannel({
    id: config.id,
    channelId: config.channelId,
    frequency: config.frequency,
    timezone: config.timezone,
    workspaceId: config.workspaceId,
  });
}

// Stop all scheduled jobs (for graceful shutdown)
export function stopScheduler(): void {
  for (const [id, job] of activeJobs) {
    job.stop();
    activeJobs.delete(id);
  }
  console.log("[scheduler] All jobs stopped");
}
