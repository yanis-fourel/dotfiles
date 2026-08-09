/**
 * skill-toggle.ts — toggle which skills are visible to the LLM.
 *
 * Pi normally injects every discovered skill's name+description into the
 * system prompt (the <available_skills> block). This extension lets you
 * disable individual skills so they're hidden from the model's context,
 * without deleting or moving the skill files on disk.
 *
 * Usage:
 *   /skills           - open an interactive enabled/disabled toggle list
 *   /skills list      - print enabled/disabled skills without opening UI
 *   /skills on <name>  - enable a skill by name
 *   /skills off <name> - disable a skill by name
 *
 * State is global (stored in a JSON file under the pi agent directory), so
 * disabling a skill sticks across restarts and across every session/project
 * — not just the session it was toggled in.
 *
 * A status widget above the input editor shows a live checkmark/cross per
 * skill so disabled (or missing) skills are visible without running /skills.
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import type { ExtensionAPI, ExtensionContext, Skill, Theme } from "@earendil-works/pi-coding-agent";
import { formatSkillsForPrompt, getAgentDir, getSettingsListTheme, loadSkillsFromDir } from "@earendil-works/pi-coding-agent";
import { Container, type SettingItem, SettingsList } from "@earendil-works/pi-tui";

interface SkillToggleState {
	disabledSkills: string[];
}

const WIDGET_KEY = "skill-toggle-status";

function getStateFilePath(): string {
	return join(getAgentDir(), "skill-toggle-state.json");
}

function loadGlobalState(): Set<string> {
	try {
		const raw = readFileSync(getStateFilePath(), "utf8");
		const data = JSON.parse(raw) as SkillToggleState;
		return new Set(data.disabledSkills ?? []);
	} catch {
		return new Set();
	}
}

function saveGlobalState(disabledSkills: Set<string>) {
	const path = getStateFilePath();
	try {
		mkdirSync(dirname(path), { recursive: true });
		writeFileSync(path, JSON.stringify({ disabledSkills: Array.from(disabledSkills) }, null, 2));
	} catch {
		// Best-effort persistence; if this fails the toggle still applies for
		// the current process, it just won't survive a restart.
	}
}

// Discover skills the same way pi does, covering the locations documented in
// docs/skills.md that the lightweight `loadSkills()` helper does not cover
// (it only scans `<agentDir>/skills` and `<cwd>/.pi/skills`).
function discoverSkills(cwd: string): Skill[] {
	const byName = new Map<string, Skill>();
	const addAll = (skills: Skill[]) => {
		for (const skill of skills) {
			if (!byName.has(skill.name)) {
				byName.set(skill.name, skill);
			}
		}
	};
	const onlySkillMd = (skills: Skill[]) => skills.filter((s) => s.filePath.endsWith("/SKILL.md") || s.filePath.endsWith("\\SKILL.md"));

	const safeLoad = (dir: string): Skill[] => {
		try {
			return loadSkillsFromDir({ dir, source: dir }).skills;
		} catch {
			return [];
		}
	};

	// ~/.pi/agent/skills — root .md files and SKILL.md dirs
	addAll(safeLoad(join(getAgentDir(), "skills")));

	// ~/.agents/skills — only SKILL.md dirs, root .md files are ignored
	addAll(onlySkillMd(safeLoad(join(homedir(), ".agents", "skills"))));

	// <cwd>/.pi/skills — root .md files and SKILL.md dirs
	addAll(safeLoad(join(cwd, ".pi", "skills")));

	// .agents/skills in cwd and ancestor directories, up to the git repo root
	// (or filesystem root when not in a repo)
	let dir = cwd;
	// eslint-disable-next-line no-constant-condition
	while (true) {
		addAll(onlySkillMd(safeLoad(join(dir, ".agents", "skills"))));
		if (existsSync(join(dir, ".git"))) {
			break;
		}
		const parent = dirname(dir);
		if (parent === dir) {
			break;
		}
		dir = parent;
	}

	return Array.from(byName.values());
}

export default function skillToggleExtension(pi: ExtensionAPI) {
	// Global state, loaded once at extension init so it's available even
	// before any session_start fires.
	let disabledSkills: Set<string> = loadGlobalState();
	// Best-effort mirror of what pi discovers, used only to render the status
	// widget. The authoritative list used for the actual prompt filtering is
	// always `event.systemPromptOptions.skills` in `before_agent_start`.
	let knownSkills: Skill[] = [];

	function persistState() {
		saveGlobalState(disabledSkills);
	}

	function refreshKnownSkills(ctx: ExtensionContext) {
		knownSkills = discoverSkills(ctx.cwd);
	}

	function buildStatusLines(theme: Theme): string[] {
		if (knownSkills.length === 0) {
			return [theme.fg("dim", "Skills: none discovered")];
		}

		const parts = knownSkills.map((skill) => {
			const disabled = disabledSkills.has(skill.name);
			const icon = disabled ? theme.fg("error", "\u274c") : theme.fg("success", "\u2705");
			return `${icon} ${skill.name}`;
		});

		const lines = [`${theme.fg("muted", "Skills:")} ${parts.join("  ")}`];

		// Flag disabled skills that no longer exist (stale state, e.g. the skill
		// was renamed or deleted) — this is the "something's wrong" signal.
		const knownNames = new Set(knownSkills.map((s) => s.name));
		const staleNames = Array.from(disabledSkills).filter((name) => !knownNames.has(name));
		if (staleNames.length > 0) {
			lines.push(theme.fg("warning", `\u26a0 disabled skill(s) no longer found: ${staleNames.join(", ")}`));
		}

		return lines;
	}

	function updateStatusWidget(ctx: ExtensionContext) {
		ctx.ui.setWidget(WIDGET_KEY, (_tui, theme) => ({
			render(_width: number) {
				return buildStatusLines(theme);
			},
			invalidate() {},
		}));
	}

	function refresh(ctx: ExtensionContext) {
		refreshKnownSkills(ctx);
		updateStatusWidget(ctx);
	}

	// Rebuild the <available_skills> block in the system prompt, excluding
	// disabled skills, using the exact same formatter pi uses internally.
	pi.on("before_agent_start", async (event) => {
		if (disabledSkills.size === 0) {
			return; // Nothing to do — no override.
		}

		const allSkills: Skill[] = event.systemPromptOptions.skills ?? [];
		if (allSkills.length === 0) {
			return;
		}

		const enabledSkills = allSkills.filter((s) => !disabledSkills.has(s.name));
		if (enabledSkills.length === allSkills.length) {
			return; // No currently-loaded skill is disabled.
		}

		const oldBlock = formatSkillsForPrompt(allSkills);
		const newBlock = formatSkillsForPrompt(enabledSkills);

		if (!oldBlock || !event.systemPrompt.includes(oldBlock)) {
			return; // Nothing to safely replace (e.g. custom prompt without read tool).
		}

		const newSystemPrompt = event.systemPrompt.replace(oldBlock, newBlock);
		return { systemPrompt: newSystemPrompt };
	});

	pi.registerCommand("skills", {
		description: "Enable/disable skills visible to the LLM",
		handler: async (args, ctx) => {
			refreshKnownSkills(ctx);
			const allSkills = knownSkills;

			if (allSkills.length === 0) {
				ctx.ui.notify("No skills discovered", "info");
				return;
			}

			const trimmed = args.trim();

			if (trimmed === "list" || trimmed === "") {
				if (trimmed === "list" || ctx.mode !== "tui") {
					const lines = allSkills.map(
						(s) => `${disabledSkills.has(s.name) ? "[ ]" : "[x]"} ${s.name} - ${s.description}`,
					);
					ctx.ui.notify(lines.join("\n"), "info");
					return;
				}
			}

			if (trimmed.startsWith("on ") || trimmed.startsWith("off ")) {
				const [action, ...rest] = trimmed.split(/\s+/);
				const name = rest.join(" ");
				const exists = allSkills.some((s) => s.name === name);
				if (!exists) {
					ctx.ui.notify(`Unknown skill: ${name}`, "error");
					return;
				}
				if (action === "on") {
					disabledSkills.delete(name);
				} else {
					disabledSkills.add(name);
				}
				persistState();
				updateStatusWidget(ctx);
				ctx.ui.notify(`Skill "${name}" ${action === "on" ? "enabled" : "disabled"}`, "info");
				return;
			}

			if (ctx.mode !== "tui") {
				ctx.ui.notify("/skills requires TUI mode for the interactive list (try /skills list, on, off)", "error");
				return;
			}

			await ctx.ui.custom((tui, theme, _kb, done) => {
				const items: SettingItem[] = allSkills.map((skill) => ({
					id: skill.name,
					label: skill.name,
					description: skill.description,
					currentValue: disabledSkills.has(skill.name) ? "\u274c" : "\u2705",
					values: ["\u2705", "\u274c"],
				}));

				const container = new Container();
				container.addChild(
					new (class {
						render(_width: number) {
							return [theme.fg("accent", theme.bold("Skill Visibility")), ""];
						}
						invalidate() {}
					})(),
				);

				const settingsList = new SettingsList(
					items,
					Math.min(items.length + 2, 15),
					getSettingsListTheme(),
					(id, newValue) => {
						if (newValue === "\u2705") {
							disabledSkills.delete(id);
						} else {
							disabledSkills.add(id);
						}
						persistState();
						updateStatusWidget(ctx);
					},
					() => {
						done(undefined);
					},
				);

				container.addChild(settingsList);

				return {
					render(width: number) {
						return container.render(width);
					},
					invalidate() {
						container.invalidate();
					},
					handleInput(data: string) {
						settingsList.handleInput?.(data);
						tui.requestRender();
					},
				};
			});
		},
	});

	pi.on("session_start", async (_event, ctx) => {
		// Reload from disk in case another pi process changed it since init.
		disabledSkills = loadGlobalState();
		refresh(ctx);
	});

	pi.on("session_tree", async (_event, ctx) => {
		refresh(ctx);
	});
}
