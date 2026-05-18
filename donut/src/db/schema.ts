import { sqliteTable, text, integer, primaryKey, uniqueIndex } from "drizzle-orm/sqlite-core";

// --- Workspaces ---

export const workspaces = sqliteTable("workspaces", {
  id: text("id").primaryKey(), // Slack team_id
  teamName: text("team_name").notNull(),
  botToken: text("bot_token").notNull(),
  installedAt: integer("installed_at", { mode: "timestamp_ms" }).notNull(),
  installedBy: text("installed_by").notNull(),
});

// --- Channel Configs ---

export const channels = sqliteTable("channels", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  workspaceId: text("workspace_id")
    .notNull()
    .references(() => workspaces.id, { onDelete: "cascade" }),
  channelId: text("channel_id").notNull(),
  channelName: text("channel_name").notNull(),
  groupSize: integer("group_size").notNull().default(3),
  frequency: text("frequency").notNull().default("0 10 * * 1"), // Mon 10am
  timezone: text("timezone").notNull().default("America/New_York"),
  cooldownRounds: integer("cooldown_rounds").notNull().default(3),
  timezoneMode: integer("timezone_mode", { mode: "boolean" }).notNull().default(false),
  isActive: integer("is_active", { mode: "boolean" }).notNull().default(true),
  createdAt: integer("created_at", { mode: "timestamp_ms" }).notNull(),
  updatedAt: integer("updated_at", { mode: "timestamp_ms" }).notNull(),
}, (table) => [
  uniqueIndex("channels_workspace_channel_idx").on(table.workspaceId, table.channelId),
]);

// --- Members ---

export const members = sqliteTable("members", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  channelConfigId: integer("channel_config_id")
    .notNull()
    .references(() => channels.id, { onDelete: "cascade" }),
  userId: text("user_id").notNull(),
  displayName: text("display_name").notNull(),
  timezone: text("timezone").default("UTC"),
  isActive: integer("is_active", { mode: "boolean" }).notNull().default(true),
  isPaused: integer("is_paused", { mode: "boolean" }).notNull().default(false),
  joinedAt: integer("joined_at", { mode: "timestamp_ms" }).notNull(),
}, (table) => [
  uniqueIndex("members_channel_user_idx").on(table.channelConfigId, table.userId),
]);

// --- Rounds ---

export const rounds = sqliteTable("rounds", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  channelConfigId: integer("channel_config_id")
    .notNull()
    .references(() => channels.id, { onDelete: "cascade" }),
  executedAt: integer("executed_at", { mode: "timestamp_ms" }).notNull(),
  groupCount: integer("group_count").notNull(),
});

// --- Pairings (groups within a round) ---

export const pairings = sqliteTable("pairings", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  roundId: integer("round_id")
    .notNull()
    .references(() => rounds.id, { onDelete: "cascade" }),
  groupIndex: integer("group_index").notNull(),
});

// --- Pairing Members (junction table) ---

export const pairingMembers = sqliteTable("pairing_members", {
  pairingId: integer("pairing_id")
    .notNull()
    .references(() => pairings.id, { onDelete: "cascade" }),
  userId: text("user_id").notNull(),
}, (table) => [
  primaryKey({ columns: [table.pairingId, table.userId] }),
]);
