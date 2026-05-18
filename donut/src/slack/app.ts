import { App, type Receiver, type ReceiverEvent } from "@slack/bolt";
import type AppType from "@slack/bolt/dist/App";
import { Hono } from "hono";
import { env } from "../env";

// Custom receiver that bridges Slack Bolt events through Hono.
// Instead of Bolt managing its own HTTP server, we parse Slack payloads
// in Hono routes and dispatch them to Bolt's event handlers.

type BoltEventHandler = (event: ReceiverEvent) => Promise<void>;

let boltEventHandler: BoltEventHandler | undefined;

const honoReceiver: Receiver = {
  init(app: AppType) {
    boltEventHandler = app.processEvent.bind(app);
  },
  start: async () => {},
  stop: async () => {},
};

export const slackApp = new App({
  token: env.slack.botToken,
  signingSecret: env.slack.signingSecret,
  receiver: honoReceiver,
});

// Dispatch a parsed Slack event through Bolt's handler pipeline
export async function dispatchSlackEvent(body: Record<string, unknown>, ack: () => Promise<void>): Promise<void> {
  if (!boltEventHandler) {
    throw new Error("Bolt event handler not initialized");
  }
  await boltEventHandler({
    body,
    ack: ack as ReceiverEvent["ack"],
  });
}

// Register Slack-specific routes on a Hono app
export function registerSlackRoutes(hono: Hono): void {
  // Slack sends URL verification challenges and events to this endpoint
  hono.post("/slack/events", async (c) => {
    const body = await c.req.json();

    // Handle URL verification challenge
    if (body.type === "url_verification") {
      return c.json({ challenge: body.challenge });
    }

    // Dispatch to Bolt
    let ackCalled = false;
    let ackBody: unknown = undefined;
    await dispatchSlackEvent(body, async () => {
      ackCalled = true;
    });

    if (ackCalled) {
      return ackBody ? c.json(ackBody) : c.text("");
    }
    return c.text("");
  });

  // Slack slash commands
  hono.post("/slack/commands", async (c) => {
    const formData = await c.req.parseBody();
    const body = {
      ...formData,
      type: "slash_command",
    };

    let ackBody: unknown = undefined;
    await dispatchSlackEvent(body as Record<string, unknown>, async () => {
      ackBody = undefined;
    });

    return ackBody ? c.json(ackBody) : c.text("");
  });

  // Slack interactive components (modals, buttons, etc.)
  hono.post("/slack/interactions", async (c) => {
    const formData = await c.req.parseBody();
    const payloadStr = formData.payload;
    if (typeof payloadStr !== "string") {
      return c.text("Invalid payload", 400);
    }
    const body = JSON.parse(payloadStr);

    let ackBody: unknown = undefined;
    await dispatchSlackEvent(body, async () => {
      ackBody = undefined;
    });

    return ackBody ? c.json(ackBody) : c.text("");
  });

  // OAuth install redirect
  hono.get("/slack/install", (c) => {
    const scopes = "chat:write,commands,users:read,channels:read,groups:read,im:write";
    const url = `https://slack.com/oauth/v2/authorize?client_id=${env.slack.clientId}&scope=${scopes}&redirect_uri=${encodeURIComponent(`${c.req.url.replace("/slack/install", "/slack/oauth_redirect")}`)}`;
    return c.redirect(url);
  });

  // OAuth callback
  hono.get("/slack/oauth_redirect", async (c) => {
    const code = c.req.query("code");
    if (!code) return c.text("Missing code parameter", 400);

    try {
      const result = await slackApp.client.oauth.v2.access({
        client_id: env.slack.clientId,
        client_secret: env.slack.clientSecret,
        code,
      });

      if (!result.ok) {
        return c.text("OAuth failed", 500);
      }

      // Store workspace credentials — will be handled by the install callback
      // For now, log success
      console.log(`Workspace installed: ${result.team?.name} (${result.team?.id})`);

      return c.html("<html><body><h1>Donut installed!</h1><p>You can close this tab.</p></body></html>");
    } catch (err) {
      console.error("OAuth error:", err);
      return c.text("OAuth error", 500);
    }
  });
}
