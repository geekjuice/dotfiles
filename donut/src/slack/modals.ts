// Slack modal views for Donut configuration

type ChannelConfig = {
  groupSize: number;
  frequency: string;
  timezone: string;
  cooldownRounds: number;
  timezoneMode: boolean;
};

const FREQUENCY_OPTIONS = [
  { text: "Weekly - Monday", value: "0 10 * * 1" },
  { text: "Weekly - Tuesday", value: "0 10 * * 2" },
  { text: "Weekly - Wednesday", value: "0 10 * * 3" },
  { text: "Weekly - Thursday", value: "0 10 * * 4" },
  { text: "Weekly - Friday", value: "0 10 * * 5" },
  { text: "Biweekly - Monday", value: "0 10 1-7,15-21 * 1" },
  { text: "Monthly - 1st Monday", value: "0 10 1-7 * 1" },
];

const COMMON_TIMEZONES = [
  "America/New_York",
  "America/Chicago",
  "America/Denver",
  "America/Los_Angeles",
  "America/Toronto",
  "Europe/London",
  "Europe/Berlin",
  "Europe/Paris",
  "Asia/Tokyo",
  "Asia/Shanghai",
  "Asia/Kolkata",
  "Australia/Sydney",
  "Pacific/Auckland",
  "UTC",
];

export function configModal(
  channelId: string,
  existing?: ChannelConfig,
): object {
  const defaults: ChannelConfig = existing ?? {
    groupSize: 3,
    frequency: "0 10 * * 1",
    timezone: "America/New_York",
    cooldownRounds: 3,
    timezoneMode: false,
  };

  return {
    type: "modal",
    callback_id: "donut_config_modal",
    private_metadata: channelId,
    title: { type: "plain_text", text: "Donut Config" },
    submit: { type: "plain_text", text: "Save" },
    close: { type: "plain_text", text: "Cancel" },
    blocks: [
      {
        type: "input",
        block_id: "group_size",
        label: { type: "plain_text", text: "Group Size" },
        element: {
          type: "number_input",
          action_id: "group_size_input",
          is_decimal_allowed: false,
          min_value: "2",
          max_value: "8",
          initial_value: String(defaults.groupSize),
          placeholder: { type: "plain_text", text: "How many people per group?" },
        },
      },
      {
        type: "input",
        block_id: "frequency",
        label: { type: "plain_text", text: "Frequency" },
        element: {
          type: "static_select",
          action_id: "frequency_select",
          initial_option: {
            text: {
              type: "plain_text",
              text: FREQUENCY_OPTIONS.find((o) => o.value === defaults.frequency)?.text ?? "Weekly - Monday",
            },
            value: defaults.frequency,
          },
          options: FREQUENCY_OPTIONS.map((o) => ({
            text: { type: "plain_text", text: o.text },
            value: o.value,
          })),
        },
      },
      {
        type: "input",
        block_id: "timezone",
        label: { type: "plain_text", text: "Schedule Timezone" },
        element: {
          type: "static_select",
          action_id: "timezone_select",
          initial_option: {
            text: { type: "plain_text", text: defaults.timezone },
            value: defaults.timezone,
          },
          options: COMMON_TIMEZONES.map((tz) => ({
            text: { type: "plain_text", text: tz },
            value: tz,
          })),
        },
      },
      {
        type: "input",
        block_id: "cooldown",
        label: { type: "plain_text", text: "Cooldown (rounds)" },
        hint: {
          type: "plain_text",
          text: "Prevent re-pairing within this many recent rounds",
        },
        element: {
          type: "number_input",
          action_id: "cooldown_input",
          is_decimal_allowed: false,
          min_value: "0",
          max_value: "20",
          initial_value: String(defaults.cooldownRounds),
        },
      },
      {
        type: "input",
        block_id: "timezone_mode",
        label: { type: "plain_text", text: "Timezone-Aware Pairing" },
        hint: {
          type: "plain_text",
          text: "When enabled, prefer grouping people in similar timezones",
        },
        element: {
          type: "static_select",
          action_id: "timezone_mode_select",
          initial_option: defaults.timezoneMode
            ? { text: { type: "plain_text", text: "On" }, value: "true" }
            : { text: { type: "plain_text", text: "Off" }, value: "false" },
          options: [
            { text: { type: "plain_text", text: "On" }, value: "true" },
            { text: { type: "plain_text", text: "Off" }, value: "false" },
          ],
        },
      },
    ],
  };
}

// Extract values from a submitted config modal
export function parseConfigModalValues(values: Record<string, Record<string, { value?: string; selected_option?: { value: string } }>>): ChannelConfig {
  return {
    groupSize: parseInt(values.group_size.group_size_input.value ?? "3", 10),
    frequency: values.frequency.frequency_select.selected_option?.value ?? "0 10 * * 1",
    timezone: values.timezone.timezone_select.selected_option?.value ?? "America/New_York",
    cooldownRounds: parseInt(values.cooldown.cooldown_input.value ?? "3", 10),
    timezoneMode: values.timezone_mode.timezone_mode_select.selected_option?.value === "true",
  };
}
