import { spawn } from "node:child_process";
import path from "node:path";

function toJson(value: unknown): string {
  try {
    return `${JSON.stringify(value ?? {}, null, 2)}\n`;
  } catch {
    return "{}\n";
  }
}

async function runHook(root: string, hookName: string, payload?: unknown): Promise<void> {
  const hookPath = path.join(root, ".codewiki", "hooks", hookName);

  try {
    await new Promise<void>((resolve) => {
      const child = spawn("bash", [hookPath], {
        cwd: root,
        stdio: ["pipe", "ignore", "ignore"]
      });

      child.on("error", () => resolve());
      child.on("close", () => resolve());

      if (payload === undefined) {
        child.stdin.end();
        return;
      }

      child.stdin.end(toJson(payload));
    });
  } catch {
    // CodeWiki hooks are advisory and must never block the host agent.
  }
}

export const CodeWikiPlugin = async ({
  directory,
  worktree
}: {
  directory?: string;
  worktree?: string;
}) => {
  const root = worktree ?? directory ?? process.cwd();

  return {
    "tool.execute.before": async (input: unknown, output: unknown) => {
      await runHook(root, "pre-wiki-context.sh", { input, output });
    },

    "file.edited": async (input: unknown, output: unknown) => {
      await runHook(root, "post-verify.sh", { input, output });
    },

    // `session.idle` is treated as assistant-idle / turn-end, not teardown.
    "session.idle": async (input: unknown) => {
      await runHook(root, "session-end.sh", input);
    }
  };
};
