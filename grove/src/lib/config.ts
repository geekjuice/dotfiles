import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { resolve, join } from "node:path";
import { homedir } from "node:os";
import { parse as parseToml } from "toml";

export type GroveConfig = {
  worktreePath: string;
  mainBranch?: string;
  shell?: string;
  editor?: string;
}

const DEFAULT_CONFIG: GroveConfig = {
  worktreePath: "~/worktrees/{{ repo }}/{{ branch }}",
};

function getConfigDir(): string {
  return join(homedir(), ".config", "grove");
}

function getConfigPath(): string {
  return join(getConfigDir(), "config.toml");
}

export function loadConfig(): GroveConfig {
  const configPath = getConfigPath();
  if (!existsSync(configPath)) {
    return DEFAULT_CONFIG;
  }

  try {
    const content = readFileSync(configPath, "utf-8");
    const parsed = parseToml(content);
    return {
      worktreePath:
        (parsed["worktree-path"] as string) || DEFAULT_CONFIG.worktreePath,
      mainBranch: parsed["main-branch"] as string | undefined,
      shell: parsed["shell"] as string | undefined,
      editor: parsed["editor"] as string | undefined,
    };
  } catch {
    return DEFAULT_CONFIG;
  }
}

export function resolveWorktreePath(
  config: GroveConfig,
  repoName: string,
  branchName: string
): string {
  const sanitized = branchName.replace(/[^a-zA-Z0-9_-]/g, "-");
  const path = config.worktreePath
    .replace("{{ repo }}", repoName)
    .replace("{{ branch }}", sanitized)
    .replace("~", homedir());
  return resolve(path);
}

export function ensureConfigDir(): void {
  const dir = getConfigDir();
  if (!existsSync(dir)) {
    mkdirSync(dir, { recursive: true });
  }
}

export function saveConfig(config: GroveConfig): void {
  ensureConfigDir();
  const content = `# Grove configuration
worktree-path = "${config.worktreePath}"
${config.mainBranch ? `main-branch = "${config.mainBranch}"` : ""}
${config.shell ? `shell = "${config.shell}"` : ""}
${config.editor ? `editor = "${config.editor}"` : ""}
`.replace(/\n\n+/g, "\n");
  writeFileSync(getConfigPath(), content);
}
