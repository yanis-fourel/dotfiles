import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import type { SkillInventory } from "./inventory/loader.ts";
import type { SkillInvocationMode } from "./types.ts";

interface SkillStatusEntryData {
  skills: Array<{ name: string; mode: SkillInvocationMode; source: string; editable: boolean }>;
}

const ENTRY_TYPE = "pi-skill-toggle-status";

/**
 * Shows, at the top of a brand-new session's conversation, which skills the
 * agent currently has access to (✅ agent-invocable) or not (❌ manual-only).
 *
 * Stored as a custom session entry: visible in the TUI transcript but never
 * sent to the LLM as context.
 */
export function registerSkillStatusEntry(pi: ExtensionAPI, inventory: SkillInventory) {
  pi.registerEntryRenderer<SkillStatusEntryData>(ENTRY_TYPE, (entry, _options, theme) => {
    const skills = entry.data?.skills ?? [];

    if (skills.length === 0) {
      return new Text(theme.fg("dim", "Skills: none discovered"), 0, 0);
    }

    const lines = [theme.fg("accent", theme.bold("Skills available to the agent:"))];
    for (const skill of skills) {
      const hasAccess = skill.mode !== "manual-only";
      const icon = hasAccess ? theme.fg("success", "\u2705") : theme.fg("error", "\u274c");
      const readonly = skill.editable ? "" : theme.fg("warning", " (read-only)");
      lines.push(`  ${icon} ${skill.name}${readonly}`);
    }

    return new Text(lines.join("\n"), 0, 0);
  });

  pi.on("session_start", async (_event, ctx) => {
    // Only show this once, at the very start of a genuinely fresh session —
    // not every time you resume one. `reason` alone is not enough: a plain
    // CLI launch that resumes the last session also reports "startup", and
    // `reason: "new"` only fires for an explicit new-session transition
    // while pi is already running (e.g. the /new command). A brand-new
    // session file already has a couple of bookkeeping entries (model /
    // thinking-level selection), so check for an actual conversation
    // message instead of an empty branch.
    const hasConversation = ctx.sessionManager.getBranch().some((e) => e.type === "message");
    if (hasConversation) return;

    let skills;
    try {
      skills = await inventory.load(ctx.cwd);
    } catch {
      return;
    }

    pi.appendEntry<SkillStatusEntryData>(ENTRY_TYPE, {
      skills: skills.map((s) => ({ name: s.name, mode: s.mode, source: s.source.kind, editable: s.editable })),
    });
  });
}
