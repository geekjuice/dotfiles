#!/usr/bin/env node
import React from "react";
import { render } from "ink";
import meow from "meow";
import { App } from "./components/App.js";

const cli = meow(
  `
  Usage
    $ grove [options]

  Options
    --cwd, -C   Repository path (defaults to current directory)
    --help      Show help
    --version   Show version

  Keys
    j/k         Move up/down
    Enter       Open shell in selected worktree
    c           Launch new Claude session in worktree
    C           Continue most recent Claude session
    R           Resume picker (choose from past sessions)
    n           Create new worktree
    d           Delete selected worktree
    s           Toggle spotlight on selected worktree
    r           Refresh worktree list
    q           Quit
`,
  {
    importMeta: import.meta,
    flags: {
      cwd: {
        type: "string",
        shortFlag: "C",
      },
    },
  }
);

// Enter alternate screen buffer for full-screen TUI
const enterAltScreen = "\x1b[?1049h";
const exitAltScreen = "\x1b[?1049l";
const hideCursor = "\x1b[?25l";
const showCursor = "\x1b[?25h";

process.stdout.write(enterAltScreen + hideCursor);

const cleanup = () => {
  process.stdout.write(showCursor + exitAltScreen);
};

// Ensure cleanup on any exit
process.on("exit", cleanup);
process.on("SIGINT", () => {
  cleanup();
  process.exit(0);
});
process.on("SIGTERM", () => {
  cleanup();
  process.exit(0);
});

const { waitUntilExit } = render(<App cwd={cli.flags.cwd} />);

waitUntilExit()
  .then(() => {
    cleanup();
    process.exit(0);
  })
  .catch(() => {
    cleanup();
    process.exit(1);
  });
