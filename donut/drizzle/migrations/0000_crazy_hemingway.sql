CREATE TABLE `channels` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`workspace_id` text NOT NULL,
	`channel_id` text NOT NULL,
	`channel_name` text NOT NULL,
	`group_size` integer DEFAULT 3 NOT NULL,
	`frequency` text DEFAULT '0 10 * * 1' NOT NULL,
	`timezone` text DEFAULT 'America/New_York' NOT NULL,
	`cooldown_rounds` integer DEFAULT 3 NOT NULL,
	`timezone_mode` integer DEFAULT false NOT NULL,
	`is_active` integer DEFAULT true NOT NULL,
	`created_at` integer NOT NULL,
	`updated_at` integer NOT NULL,
	FOREIGN KEY (`workspace_id`) REFERENCES `workspaces`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE UNIQUE INDEX `channels_workspace_channel_idx` ON `channels` (`workspace_id`,`channel_id`);--> statement-breakpoint
CREATE TABLE `members` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`channel_config_id` integer NOT NULL,
	`user_id` text NOT NULL,
	`display_name` text NOT NULL,
	`timezone` text DEFAULT 'UTC',
	`is_active` integer DEFAULT true NOT NULL,
	`is_paused` integer DEFAULT false NOT NULL,
	`joined_at` integer NOT NULL,
	FOREIGN KEY (`channel_config_id`) REFERENCES `channels`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE UNIQUE INDEX `members_channel_user_idx` ON `members` (`channel_config_id`,`user_id`);--> statement-breakpoint
CREATE TABLE `pairing_members` (
	`pairing_id` integer NOT NULL,
	`user_id` text NOT NULL,
	PRIMARY KEY(`pairing_id`, `user_id`),
	FOREIGN KEY (`pairing_id`) REFERENCES `pairings`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `pairings` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`round_id` integer NOT NULL,
	`group_index` integer NOT NULL,
	FOREIGN KEY (`round_id`) REFERENCES `rounds`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `rounds` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`channel_config_id` integer NOT NULL,
	`executed_at` integer NOT NULL,
	`group_count` integer NOT NULL,
	FOREIGN KEY (`channel_config_id`) REFERENCES `channels`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `workspaces` (
	`id` text PRIMARY KEY NOT NULL,
	`team_name` text NOT NULL,
	`bot_token` text NOT NULL,
	`installed_at` integer NOT NULL,
	`installed_by` text NOT NULL
);
