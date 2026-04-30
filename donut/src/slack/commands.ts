import { eq, and } from "drizzle-orm";
import type { KnownBlock } from "@slack/types";
import { slackApp } from "./app";
import { db } from "../db/client";
import { channels, members } from "../db/schema";
import { generatePairings } from "../pairing/engine";
import { recordRound } from "../pairing/history";
import { configModal, parseConfigModalValues } from "./modals";
import {
  pairingDmBlocks,
  roundAnnouncementBlocks,
  joinConfirmation,
  leaveConfirmation,
  pauseConfirmation,
  resumeConfirmation,
  statusMessage,
  alreadySetup,
  notSetup,
  notEnoughMembers,
  triggerSuccess,
} from "./messages";

// Parse subcommand from slash command text
function parseSubcommand(text: string): { subcommand: string; args: string } {
  const trimmed = text.trim();
  const spaceIdx = trimmed.indexOf(" ");
  if (spaceIdx === -1) return { subcommand: trimmed.toLowerCase(), args: "" };
  return {
    subcommand: trimmed.slice(0, spaceIdx).toLowerCase(),
    args: trimmed.slice(spaceIdx + 1).trim(),
  };
}

// Get or return null for channel config
async function getChannelConfig(workspaceId: string, channelId: string) {
  const [config] = await db
    .select()
    .from(channels)
    .where(and(eq(channels.workspaceId, workspaceId), eq(channels.channelId, channelId)))
    .limit(1);
  return config ?? null;
}

// Get active member count for a channel config
async function getActiveMemberCount(channelConfigId: number): Promise<number> {
  const result = await db
    .select()
    .from(members)
    .where(and(eq(members.channelConfigId, channelConfigId), eq(members.isActive, true)));
  return result.length;
}

// Execute a pairing round for a channel
export async function executePairingRound(
  channelConfigId: number,
  channelId: string,
  botToken: string,
): Promise<{ groupCount: number } | { error: string }> {
  const [config] = await db
    .select()
    .from(channels)
    .where(eq(channels.id, channelConfigId))
    .limit(1);

  if (!config) return { error: "Channel config not found" };

  const activeMembers = await db
    .select()
    .from(members)
    .where(
      and(
        eq(members.channelConfigId, channelConfigId),
        eq(members.isActive, true),
        eq(members.isPaused, false),
      ),
    );

  if (activeMembers.length < 2) return { error: "Not enough members" };

  const groups = await generatePairings({
    channelConfigId,
    members: activeMembers.map((m) => ({ userId: m.userId, timezone: m.timezone })),
    groupSize: config.groupSize,
    cooldownRounds: config.cooldownRounds,
    timezoneMode: config.timezoneMode,
  });

  if (groups.length === 0) return { error: "Could not form any groups" };

  // Record the round
  await recordRound(channelConfigId, groups);

  // Send DMs to each group
  for (const group of groups) {
    // Open a multi-person DM
    try {
      const conversation = await slackApp.client.conversations.open({
        token: botToken,
        users: group.join(","),
      });

      if (conversation.channel?.id) {
        await slackApp.client.chat.postMessage({
          token: botToken,
          channel: conversation.channel.id,
          blocks: pairingDmBlocks(group) as KnownBlock[],
          text: `You've been paired for a coffee chat! Meet: ${group.map((u) => `<@${u}>`).join(", ")}`,
        });
      }
    } catch (err) {
      console.error(`Failed to DM group [${group.join(", ")}]:`, err);
    }
  }

  // Post channel announcement
  try {
    await slackApp.client.chat.postMessage({
      token: botToken,
      channel: channelId,
      blocks: roundAnnouncementBlocks(groups.length, config.groupSize) as KnownBlock[],
      text: `A new Donut round just ran! ${groups.length} groups paired.`,
    });
  } catch (err) {
    console.error("Failed to post channel announcement:", err);
  }

  return { groupCount: groups.length };
}

// Register the /donut slash command
export function registerCommands(): void {
  slackApp.command("/donut", async ({ command, ack, respond, client }) => {
    const { subcommand } = parseSubcommand(command.text);
    const workspaceId = command.team_id;
    const channelId = command.channel_id;
    const userId = command.user_id;

    switch (subcommand) {
      case "setup": {
        await ack();
        const existing = await getChannelConfig(workspaceId, channelId);
        if (existing) {
          await respond({ text: alreadySetup(channelId), response_type: "ephemeral" });
          return;
        }

        // Create channel config with defaults
        const [newConfig] = await db
          .insert(channels)
          .values({
            workspaceId,
            channelId,
            channelName: command.channel_name,
            createdAt: new Date(),
            updatedAt: new Date(),
          })
          .returning();

        // Open config modal
        await client.views.open({
          trigger_id: command.trigger_id,
          view: configModal(channelId, {
            groupSize: newConfig.groupSize,
            frequency: newConfig.frequency,
            timezone: newConfig.timezone,
            cooldownRounds: newConfig.cooldownRounds,
            timezoneMode: newConfig.timezoneMode,
          }) as Parameters<typeof client.views.open>[0]["view"],
        });
        break;
      }

      case "join": {
        await ack();
        const config = await getChannelConfig(workspaceId, channelId);
        if (!config) {
          await respond({ text: notSetup(channelId), response_type: "ephemeral" });
          return;
        }

        // Get user info for display name and timezone
        const userInfo = await client.users.info({ user: userId });
        const displayName = userInfo.user?.real_name ?? userInfo.user?.name ?? userId;
        const userTz = userInfo.user?.tz ?? "UTC";

        // Upsert member
        const existingMember = await db
          .select()
          .from(members)
          .where(and(eq(members.channelConfigId, config.id), eq(members.userId, userId)))
          .limit(1);

        if (existingMember.length > 0) {
          await db
            .update(members)
            .set({ isActive: true, isPaused: false, displayName, timezone: userTz })
            .where(eq(members.id, existingMember[0].id));
        } else {
          await db.insert(members).values({
            channelConfigId: config.id,
            userId,
            displayName,
            timezone: userTz,
            joinedAt: new Date(),
          });
        }

        await respond({ text: joinConfirmation(channelId), response_type: "ephemeral" });
        break;
      }

      case "leave": {
        await ack();
        const config = await getChannelConfig(workspaceId, channelId);
        if (!config) {
          await respond({ text: notSetup(channelId), response_type: "ephemeral" });
          return;
        }

        await db
          .update(members)
          .set({ isActive: false })
          .where(and(eq(members.channelConfigId, config.id), eq(members.userId, userId)));

        await respond({ text: leaveConfirmation(channelId), response_type: "ephemeral" });
        break;
      }

      case "pause": {
        await ack();
        const config = await getChannelConfig(workspaceId, channelId);
        if (!config) {
          await respond({ text: notSetup(channelId), response_type: "ephemeral" });
          return;
        }

        await db
          .update(members)
          .set({ isPaused: true })
          .where(and(eq(members.channelConfigId, config.id), eq(members.userId, userId)));

        await respond({ text: pauseConfirmation(channelId), response_type: "ephemeral" });
        break;
      }

      case "resume": {
        await ack();
        const config = await getChannelConfig(workspaceId, channelId);
        if (!config) {
          await respond({ text: notSetup(channelId), response_type: "ephemeral" });
          return;
        }

        await db
          .update(members)
          .set({ isPaused: false })
          .where(and(eq(members.channelConfigId, config.id), eq(members.userId, userId)));

        await respond({ text: resumeConfirmation(channelId), response_type: "ephemeral" });
        break;
      }

      case "config": {
        await ack();
        const config = await getChannelConfig(workspaceId, channelId);
        if (!config) {
          await respond({ text: notSetup(channelId), response_type: "ephemeral" });
          return;
        }

        await client.views.open({
          trigger_id: command.trigger_id,
          view: configModal(channelId, {
            groupSize: config.groupSize,
            frequency: config.frequency,
            timezone: config.timezone,
            cooldownRounds: config.cooldownRounds,
            timezoneMode: config.timezoneMode,
          }) as Parameters<typeof client.views.open>[0]["view"],
        });
        break;
      }

      case "status": {
        await ack();
        const config = await getChannelConfig(workspaceId, channelId);
        if (!config) {
          await respond({ text: notSetup(channelId), response_type: "ephemeral" });
          return;
        }

        const memberCount = await getActiveMemberCount(config.id);

        await respond({
          blocks: statusMessage({
            channelId,
            groupSize: config.groupSize,
            frequency: config.frequency,
            timezone: config.timezone,
            cooldownRounds: config.cooldownRounds,
            timezoneMode: config.timezoneMode,
            memberCount,
            isActive: config.isActive,
          }) as KnownBlock[],
          response_type: "ephemeral",
        });
        break;
      }

      case "trigger": {
        await ack();
        const config = await getChannelConfig(workspaceId, channelId);
        if (!config) {
          await respond({ text: notSetup(channelId), response_type: "ephemeral" });
          return;
        }

        const memberCount = await getActiveMemberCount(config.id);
        if (memberCount < 2) {
          await respond({ text: notEnoughMembers(), response_type: "ephemeral" });
          return;
        }

        // Find workspace bot token
        const result = await executePairingRound(config.id, channelId, command.token);
        if ("error" in result) {
          await respond({ text: `:x: ${result.error}`, response_type: "ephemeral" });
          return;
        }

        await respond({ text: triggerSuccess(result.groupCount), response_type: "ephemeral" });
        break;
      }

      default: {
        await ack();
        await respond({
          text: [
            ":doughnut: *Donut Commands:*",
            "`/donut setup` — Enable Donut in this channel",
            "`/donut join` — Join the pairing pool",
            "`/donut leave` — Leave the pairing pool",
            "`/donut pause` — Skip upcoming rounds",
            "`/donut resume` — Unpause yourself",
            "`/donut config` — Configure settings (admin)",
            "`/donut status` — View current config & stats",
            "`/donut trigger` — Run a pairing round now (admin)",
          ].join("\n"),
          response_type: "ephemeral",
        });
      }
    }
  });

  // Handle config modal submission
  slackApp.view("donut_config_modal", async ({ ack, view, body }) => {
    await ack();

    const channelId = view.private_metadata;
    const config = parseConfigModalValues(
      view.state.values as Parameters<typeof parseConfigModalValues>[0],
    );
    const workspaceId = body.team?.id;
    if (!workspaceId) return;

    await db
      .update(channels)
      .set({
        groupSize: config.groupSize,
        frequency: config.frequency,
        timezone: config.timezone,
        cooldownRounds: config.cooldownRounds,
        timezoneMode: config.timezoneMode,
        updatedAt: new Date(),
      })
      .where(and(eq(channels.workspaceId, workspaceId), eq(channels.channelId, channelId)));
  });
}
