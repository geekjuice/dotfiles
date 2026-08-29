import { eq } from "drizzle-orm";
import { slackApp } from "./app";
import { db } from "../db/client";
import { channels, members } from "../db/schema";

export function registerEvents(): void {
  // App Home opened — show user their Donut status
  slackApp.event("app_home_opened", async ({ event, client }) => {
    const userId = event.user;

    // Find all channels this user is a member of
    const userMemberships = await db
      .select({
        channelId: channels.channelId,
        channelName: channels.channelName,
        isActive: members.isActive,
        isPaused: members.isPaused,
      })
      .from(members)
      .innerJoin(channels, eq(members.channelConfigId, channels.id))
      .where(eq(members.userId, userId));

    const blocks: object[] = [
      {
        type: "header",
        text: { type: "plain_text", text: ":doughnut: Donut" },
      },
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text: "Welcome to Donut! Get randomly paired with teammates for coffee chats.",
        },
      },
      { type: "divider" },
    ];

    if (userMemberships.length === 0) {
      blocks.push({
        type: "section",
        text: {
          type: "mrkdwn",
          text: "You haven't joined Donut in any channels yet. Use `/donut join` in a channel that has Donut set up.",
        },
      });
    } else {
      blocks.push({
        type: "section",
        text: { type: "mrkdwn", text: "*Your Channels:*" },
      });

      for (const membership of userMemberships) {
        const statusEmoji = membership.isPaused
          ? ":pause_button:"
          : membership.isActive
            ? ":large_green_circle:"
            : ":red_circle:";
        const statusText = membership.isPaused
          ? "Paused"
          : membership.isActive
            ? "Active"
            : "Opted out";

        blocks.push({
          type: "section",
          text: {
            type: "mrkdwn",
            text: `${statusEmoji} <#${membership.channelId}> — ${statusText}`,
          },
        });
      }
    }

    blocks.push(
      { type: "divider" },
      {
        type: "context",
        elements: [
          {
            type: "mrkdwn",
            text: "Commands: `/donut join` · `/donut leave` · `/donut pause` · `/donut resume` · `/donut status`",
          },
        ],
      },
    );

    try {
      await client.views.publish({
        user_id: userId,
        view: {
          type: "home",
          blocks: blocks as Parameters<typeof client.views.publish>[0]["view"]["blocks"],
        },
      });
    } catch (err) {
      console.error("Failed to publish App Home:", err);
    }
  });
}
