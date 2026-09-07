/**
 * Azure CLI Approval Gate
 *
 * Global rule: ALWAYS require explicit approval before running any Azure CLI
 * (`az ...`) command. Azure CLI commands can access subscriptions, secrets,
 * and make state-changing operations against cloud resources, so they must
 * never run unattended.
 *
 * In interactive (TUI/RPC) mode the user is prompted to confirm before the
 * command runs. In non-interactive mode (no UI), the command is blocked by
 * default so nothing executes without an explicit decision.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  // Match a command that starts with the `az` Azure CLI binary, allowing for
  // optional leading whitespace, an `az.exe` on Windows, and the command
  // being invoked via a shell alias / `env az`. It intentionally avoids
  // matching unrelated uses of "az" inside longer strings.
  const azCliPattern = /(^|[\s;&|(])(az(\.exe)?)(\s|$)/i;

  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash") return undefined;

    const command = event.input.command as string;
    const isAzCli = azCliPattern.test(command);

    if (!isAzCli) return undefined;

    if (!ctx.hasUI) {
      // Non-interactive mode: block by default so az never runs unattended.
      return {
        block: true,
        reason:
          "Azure CLI command requires approval. Re-run interactively to approve, or use --approve.",
      };
    }

    const approved = await ctx.ui.confirm(
      "Azure CLI requires approval",
      `An Azure CLI command is about to run:\n\n  ${command}\n\nAllow it?`,
    );

    if (!approved) {
      return { block: true, reason: "Azure CLI command blocked by user." };
    }

    return undefined;
  });
}
