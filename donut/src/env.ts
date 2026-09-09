const requiredEnv = (key: string): string => {
  const value = Bun.env[key];
  if (!value) throw new Error(`Missing required env var: ${key}`);
  return value;
};

export const env = {
  slack: {
    botToken: requiredEnv("SLACK_BOT_TOKEN"),
    signingSecret: requiredEnv("SLACK_SIGNING_SECRET"),
    clientId: requiredEnv("SLACK_CLIENT_ID"),
    clientSecret: requiredEnv("SLACK_CLIENT_SECRET"),
    stateSecret: Bun.env.SLACK_STATE_SECRET ?? "donut-state-secret",
  },
  port: Number(Bun.env.PORT ?? 3000),
  host: Bun.env.HOST ?? "0.0.0.0",
  databaseUrl: Bun.env.DATABASE_URL ?? "./donut.db",
} as const;
