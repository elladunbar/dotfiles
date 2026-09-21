/**
 * Read-Only Permissions Extension
 *
 * Adds a "readOnly" permission mode that plugs into pi-permissions.
 *
 * In readOnly mode:
 *   - All read tools are allowed (read, read_symbol, module_report, symbol_search, etc.)
 *   - write and edit tools are blocked (no exceptions)
 *   - Only safe read-only bash commands are allowed
 *   - File redirects (> and >>) are blocked
 *   - fd -x / --exec is blocked
 *   - Pipes are checked: every segment must be read-only
 *
 * When NOT in readOnly mode, this extension passes through to other
 * permission handlers (e.g. pi-permissions' own modes).
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

// ─── Mode config ───────────────────────────────────────────────────────────

const MODE_ID = "readOnly" as const;
const MODE_LABEL = "Read Only";
const MODE_DESCRIPTION = "Read everything, block all writes, allow safe bash";

// ─── Read-only command allowlists ──────────────────────────────────────────

const READONLY_COMMANDS = new Set([
  // File browsing / listing
  "ls", "tree", "pwd",

  // File content reading
  "cat", "tac", "head", "tail", "less", "more", "nl",

  // File metadata / info
  "stat", "file", "wc", "du", "df", "diff", "cmp",
  "md5sum", "sha256sum", "cksum", "shasum",

  // Search
  "rg", "ripgrep", "grep", "egrep", "fgrep",
  "sed", "awk", "gawk", "mawk",

  // File finders
  "fd", "fdfind", "find",

  // Git (read-only subcommands checked separately)
  "git",

  // System / environment info
  "env", "printenv", "id", "whoami", "uname", "hostname",
  "uptime", "date", "cal",
  "which", "whereis", "type", "command", "whatis",
  "ps", "top", "htop", "pgrep", "pidof",
  "mount", "free",

  // Network read-only (no connect/write)
  "ping", "traceroute", "tracepath",
  "dig", "nslookup", "host",
  "ss", "netstat",

  // Help / docs
  "man", "info",
]);

const GIT_READONLY_SUBCOMMANDS = new Set([
  "status",
  "log",
  "shortlog",
  "blame",
  "diff",
  "show",
  "branch",
  "tag",
  "remote",
  "rev-parse",
  "stash",
  "reflog",
  "describe",
  "for-each-ref",
  "ls-files",
  "ls-tree",
  "cat-file",
  "name-rev",
  "verify-tag",
]);

// Commands that must never appear in a pipe chain (they write files)
const PIPE_PROHIBITED = new Set([
  "tee",
  "xargs",
  "cp",
  "mv",
  "ln",
  "install",
  "dd",
  "truncate",
  "shred",
]);

// ─── Helpers ───────────────────────────────────────────────────────────────

/**
 * Detect file redirection operators (> or >>) in a command.
 * Strips quoted strings first to avoid false positives from literal > chars.
 */
function hasRedirect(command: string): boolean {
  const cleaned = command.replace(/"[^"]*"/g, "").replace(/'[^']*'/g, "");
  return /(^|\s)[>]{1,2}\S/.test(cleaned);
}

/**
 * Check each segment of a piped command. Returns block reason if any
 * segment is not read-only, or undefined if all segments are safe.
 */
function checkPipeSegments(command: string): { block: true; reason: string } | undefined {
  const segments = command.split("|").map((s) => s.trim());

  for (const segment of segments) {
    if (!segment) continue;

    const cmd = segment.split(/\s+/)[0];

    // Must be in the allowlist
    if (!READONLY_COMMANDS.has(cmd)) {
      return { block: true, reason: `Non-read-only command in pipe: ${cmd}` };
    }

    // Pipe-prohibited commands (write to files)
    if (PIPE_PROHIBITED.has(cmd)) {
      return { block: true, reason: `Pipe-prohibited command: ${cmd}` };
    }

    // fd --exec / -x is dangerous even though fd itself is read-only
    if ((cmd === "fd" || cmd === "fdfind") && (segment.includes("-x") || segment.includes("--exec"))) {
      return { block: true, reason: "fd -x (--exec) blocked in read-only mode" };
    }
  }

  return undefined; // all segments are safe
}

/**
 * Full bash command validation for readOnly mode.
 * Returns { block: true, reason } if the command should be blocked,
 * or undefined if it's allowed.
 */
function validateReadOnlyBash(command: string): { block: true; reason: string } | undefined {
  const trimmed = command.trim();
  if (!trimmed) return undefined; // empty command, allow

  // 1. Block file redirects (> and >>)
  if (hasRedirect(trimmed)) {
    return { block: true, reason: "File redirections (> / >>) are blocked in read-only mode" };
  }

  // 2. Handle pipes: every segment must be read-only
  if (trimmed.includes("|")) {
    const pipeResult = checkPipeSegments(trimmed);
    if (pipeResult) return pipeResult;
    return undefined; // all pipe segments are safe
  }

  // 3. Extract base command
  const cmdBase = trimmed.split(/\s+/)[0];

  // 4. Must be in the read-only allowlist
  if (!READONLY_COMMANDS.has(cmdBase)) {
    return { block: true, reason: `Command not allowed in read-only mode: ${cmdBase}` };
  }

  // 5. Git subcommand check
  if (cmdBase === "git") {
    const subCmd = trimmed.split(/\s+/)[1];
    if (!subCmd || !GIT_READONLY_SUBCOMMANDS.has(subCmd)) {
      return { block: true, reason: `Non-read-only git command: git ${subCmd}` };
    }
  }

  // 6. fd --exec / -x check (extra safety)
  if ((cmdBase === "fd" || cmdBase === "fdfind") && (trimmed.includes("-x") || trimmed.includes("--exec"))) {
    return { block: true, reason: "fd -x (--exec) is blocked in read-only mode" };
  }

  // 7. find -exec check (similar danger to fd -x)
  if (cmdBase === "find" && (trimmed.includes("-exec") || trimmed.includes("+"))) {
    return { block: true, reason: "find -exec is blocked in read-only mode" };
  }

  return undefined; // command is safe
}

// ─── Extension entry point ────────────────────────────────────────────────

export default async function (pi: ExtensionAPI) {
  let active = false;

  // Register CLI flag (Claude Code compatible)
  pi.registerFlag("read-only", {
    description: "Enable read-only permission mode",
    type: "boolean",
    default: false,
  });

  pi.registerFlag("readonly", {
    description: "Enable read-only permission mode (alias)",
    type: "boolean",
    default: false,
  });

  // Apply CLI flag on session start
  pi.on("session_start", async () => {
    active =
      pi.getFlag("read-only") === true ||
      pi.getFlag("readonly") === true;
  });

  // ── Permission gate ──────────────────────────────────────────────────

  pi.on("tool_call", async (event, ctx) => {
    // Only enforce when readOnly mode is active
    if (!active) return;

    const toolName = event.toolName;

    // Block write and edit tools — no exceptions in readOnly mode
    if (toolName === "write" || toolName === "edit") {
      return {
        block: true,
        reason: `${toolName} is blocked in read-only mode`,
      };
    }

    // Validate bash commands
    if (toolName === "bash") {
      const command = String(event.input.command ?? "");
      return validateReadOnlyBash(command);
    }

    // Allow everything else (read, read_symbol, module_report,
    // symbol_search, project_report, read_enclosing, etc.)
    return;
  });

  // ── Status widget ────────────────────────────────────────────────────

  pi.on("session_start", async (_event, ctx) => {
    if (active) {
      ctx.ui.setStatus("permissions", `🔒 ${MODE_LABEL}`);
    } else {
      ctx.ui.setStatus("permissions", undefined);
    }
  });

  // ── Commands ─────────────────────────────────────────────────────────

  pi.registerCommand("readonly", {
    description: "Show or enable read-only permission mode",
    handler: async (args, ctx) => {
      if (args && args.trim().toLowerCase() === "on") {
        active = true;
        ctx.ui.setStatus("permissions", `🔒 ${MODE_LABEL}`);
        ctx.ui.notify(`Read-only mode: enabled`, "info");
        return;
      }

      if (!args || !args.trim()) {
        const status = active ? "ACTIVE" : "INACTIVE";
        ctx.ui.notify(
          `Read-Only Mode: ${status}\n\n${MODE_DESCRIPTION}\n\nUsage: /readonly on`,
          "info",
        );
        return;
      }

      ctx.ui.notify(
        `Unknown argument. Use: /readonly on`,
        "error",
      );
    },
  });

  pi.registerCommand("readonly:status", {
    description: "Show read-only permission mode status",
    handler: async (_args, ctx) => {
      const status = active ? "ACTIVE" : "INACTIVE";
      ctx.ui.notify(
        `Read-Only Mode: ${status}\n\n${MODE_DESCRIPTION}`,
        "info",
      );
    },
  });

  // ── Keyboard shortcut: toggle readOnly mode ──────────────────────────

  pi.registerShortcut("ctrl+shift+r", {
    description: "Toggle read-only permission mode",
    handler: async (ctx) => {
      active = !active;
      if (active) {
        ctx.ui.setStatus("permissions", `🔒 ${MODE_LABEL}`);
        ctx.ui.notify(`Read-only mode: enabled`, "info");
      } else {
        ctx.ui.setStatus("permissions", undefined);
        ctx.ui.notify(`Read-only mode: disabled`, "info");
      }
    },
  });
}
