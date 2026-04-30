import { Hono } from "hono";
import { logger } from "hono/logger";
import { env } from "./env";
import { registerSlackRoutes } from "./slack/app";
import { registerCommands } from "./slack/commands";
import { registerEvents } from "./slack/events";
import { startScheduler, stopScheduler } from "./pairing/scheduler";

const app = new Hono();

// Middleware
app.use(logger());

// Health check
app.get("/", (c) => c.json({ status: "ok", app: "donut", version: "0.0.1" }));

// Slack routes (events, commands, interactions, OAuth)
registerSlackRoutes(app);
registerCommands();
registerEvents();

// Start cron scheduler for recurring pairing rounds
startScheduler().catch((err) => console.error("[startup] Scheduler failed:", err));

// Graceful shutdown
process.on("SIGINT", () => {
  console.log("Shutting down...");
  stopScheduler();
  process.exit(0);
});

console.log(`Donut starting on ${env.host}:${env.port}`);

export default {
  port: env.port,
  hostname: env.host,
  fetch: app.fetch,
};
