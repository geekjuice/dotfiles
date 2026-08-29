// Slack Block Kit message templates for Donut notifications

export function pairingDmBlocks(groupMembers: string[]): object[] {
  const mentions = groupMembers.map((uid) => `<@${uid}>`).join(", ");
  return [
    {
      type: "section",
      text: {
        type: "mrkdwn",
        text: `:doughnut: *You've been paired for a coffee chat!*\n\nMeet: ${mentions}`,
      },
    },
    {
      type: "section",
      text: {
        type: "mrkdwn",
        text: "Find a time that works for everyone and grab coffee (or tea, or a walk). Have fun!",
      },
    },
    {
      type: "context",
      elements: [
        {
          type: "mrkdwn",
          text: "_Powered by Donut_",
        },
      ],
    },
  ];
}

export function roundAnnouncementBlocks(
  groupCount: number,
  groupSize: number,
): object[] {
  return [
    {
      type: "section",
      text: {
        type: "mrkdwn",
        text: `:doughnut: *A new Donut round just ran!*\n\n${groupCount} groups of ~${groupSize} have been paired. Check your DMs!`,
      },
    },
  ];
}

export function joinConfirmation(channelId: string): string {
  return `:white_check_mark: You've joined Donut in <#${channelId}>! You'll be included in the next pairing round.`;
}

export function leaveConfirmation(channelId: string): string {
  return `You've left Donut in <#${channelId}>. You won't be included in future pairings.`;
}

export function pauseConfirmation(channelId: string): string {
  return `:pause_button: You're paused in <#${channelId}>. Use \`/donut resume\` when you're ready to come back.`;
}

export function resumeConfirmation(channelId: string): string {
  return `:arrow_forward: You're back! You'll be included in the next Donut round in <#${channelId}>.`;
}

export function statusMessage(config: {
  channelId: string;
  groupSize: number;
  frequency: string;
  timezone: string;
  cooldownRounds: number;
  timezoneMode: boolean;
  memberCount: number;
  isActive: boolean;
}): object[] {
  const statusEmoji = config.isActive ? ":large_green_circle:" : ":red_circle:";
  const tzMode = config.timezoneMode ? "On" : "Off";

  return [
    {
      type: "section",
      text: {
        type: "mrkdwn",
        text: `:doughnut: *Donut Status for <#${config.channelId}>*`,
      },
    },
    {
      type: "section",
      fields: [
        { type: "mrkdwn", text: `*Status:* ${statusEmoji} ${config.isActive ? "Active" : "Paused"}` },
        { type: "mrkdwn", text: `*Group Size:* ${config.groupSize}` },
        { type: "mrkdwn", text: `*Schedule:* \`${config.frequency}\`` },
        { type: "mrkdwn", text: `*Timezone:* ${config.timezone}` },
        { type: "mrkdwn", text: `*Cooldown:* ${config.cooldownRounds} rounds` },
        { type: "mrkdwn", text: `*TZ Pairing:* ${tzMode}` },
        { type: "mrkdwn", text: `*Members:* ${config.memberCount}` },
      ],
    },
  ];
}

export function setupConfirmation(channelId: string): string {
  return `:white_check_mark: Donut is now set up in <#${channelId}>! Members can join with \`/donut join\`.`;
}

export function alreadySetup(channelId: string): string {
  return `Donut is already set up in <#${channelId}>. Use \`/donut config\` to change settings.`;
}

export function notSetup(channelId: string): string {
  return `Donut isn't set up in <#${channelId}> yet. An admin can run \`/donut setup\` to get started.`;
}

export function notEnoughMembers(): string {
  return "Not enough members to form a group. At least 2 members need to join first!";
}

export function triggerSuccess(groupCount: number): string {
  return `:doughnut: Done! ${groupCount} groups have been paired. Check your DMs!`;
}
