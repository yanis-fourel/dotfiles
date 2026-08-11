/**
 * /work-review — isolated coder → reviewer loop with a live + full-history split viewer.
 *
 * Spawns two independent, in-memory AgentSessions via the SDK (not the model-driven
 * `task` tool), so isolation is enforced by code, not by prompt discipline:
 *
 *  - The coder session gets real read/write/exec tools scoped to the project cwd and
 *    implements the requested change directly in the working tree.
 *  - The reviewer session gets read-only tools and never sees the coder's thinking,
 *    tool calls, or intermediate turns — only the coder's final text summary plus
 *    whatever it independently reads from the repository.
 *  - The coder never sees the reviewer's thinking either — only the reviewer's final
 *    feedback text, fed back as the next prompt.
 *
 * The reviewer's verdict is captured through a dedicated `submit_verdict` tool call
 * (a boolean + optional feedback string), not by regex-matching its free-text reply —
 * a typed boolean can't drift into ambiguous phrasing the way "APPROVE" in prose can.
 *
 * Every thinking/text/tool event from both child sessions is recorded, in full, into an
 * in-memory transcript (`RunHistory`) for the lifetime of the extension process — not
 * just a truncated tail. `/work-review-view` opens a split-screen viewer (coder left,
 * reviewer right) over that transcript: independently scrollable per pane, live-updating
 * while the run is in progress, and still browsable after it finishes. It can be opened
 * at any point — including while `/work-review` is still running, since extension
 * commands dispatch independently of each other.
 */
import type { ThinkingLevel } from "@oh-my-pi/pi-agent-core";
import type {
	AgentSession,
	AgentSessionEvent,
	CustomTool,
	ExtensionAPI,
	ExtensionCommandContext,
	Theme,
	ThemeColor,
} from "@oh-my-pi/pi-coding-agent";
import { AgentRegistry, createAgentSession, SessionManager, Settings, z } from "@oh-my-pi/pi-coding-agent";
import type { AssistantMessage, Model, ToolChoice } from "@oh-my-pi/pi-ai";
import type { Component, TUI } from "@oh-my-pi/pi-tui";
import { matchesKey, ScrollView, visibleWidth, wrapTextWithAnsi } from "@oh-my-pi/pi-tui";

// Tool split is the actual isolation/safety boundary for the reviewer: it can run
// tests/greps/reads but has no edit/write/ast_edit access.
const CODER_TOOLS = ["read", "edit", "write", "bash", "grep", "glob", "ast_grep", "todo"];
const REVIEWER_TOOLS = ["read", "grep", "glob", "bash", "ast_grep", "web_search", "submit_verdict"];

const THINKING_LEVELS: readonly ThinkingLevel[] = ["off", "minimal", "low", "medium", "high", "xhigh", "max"];
const ROUND_OPTIONS = ["3", "5", "8", "12"];
const DEFAULT_ROUNDS = "5";

interface Verdict {
	approved: boolean;
	/** Concrete, actionable issues. Empty when approved. */
	feedback: string;
}

interface RoundEntry {
	round: number;
	coderSummary: string;
	approved: boolean;
	feedback: string;
}

interface WorkReviewChoice {
	task: string;
	coderModel: Model;
	coderThinking: ThinkingLevel | undefined;
	reviewerModel: Model;
	reviewerThinking: ThinkingLevel | undefined;
	maxRounds: number;
}

// ── Full-history transcript model ──────────────────────────────────────────
// Kept in memory for the process lifetime (overwritten by the next /work-review),
// independent of the compact status line, so /work-review-view can show everything
// since the beginning of the run, not just a recent tail.

type BlockKind = "thinking" | "text" | "tool" | "phase";

interface HistoryBlock {
	kind: BlockKind;
	text: string;
}

interface SessionLog {
	blocks: HistoryBlock[];
	/** Kind of the last block, when it's still accepting appended deltas (thinking/text only). */
	openKind: BlockKind | undefined;
}

interface RunHistory {
	task: string;
	coderLabel: string;
	reviewerLabel: string;
	coder: SessionLog;
	reviewer: SessionLog;
	status: string;
}

/** The run `/work-review-view` shows: the in-progress run, or the last completed one. */
let activeRun: RunHistory | undefined;

function createSessionLog(): SessionLog {
	return { blocks: [], openKind: undefined };
}

function appendDelta(log: SessionLog, kind: "thinking" | "text", delta: string): void {
	const last = log.blocks.at(-1);
	if (log.openKind === kind && last) {
		last.text += delta;
	} else {
		log.blocks.push({ kind, text: delta });
		log.openKind = kind;
	}
}

function pushAtomicBlock(log: SessionLog, kind: "tool" | "phase", text: string): void {
	log.blocks.push({ kind, text });
	log.openKind = undefined;
}

/** Best-effort single-line description of a tool call, for the transcript. */
function summarizeToolArgs(toolName: string, args: unknown): string {
	if (args && typeof args === "object") {
		const a = args as Record<string, unknown>;
		if (toolName === "submit_verdict" && typeof a.approved === "boolean") {
			return `submit_verdict: approved=${a.approved}`;
		}
		const candidate = a.command ?? a.path ?? a.pattern ?? a.query ?? a.url;
		if (typeof candidate === "string") return `${toolName}: ${candidate}`;
	}
	return toolName;
}

/** Subscribes a child session's events into its transcript log. Returns the unsubscribe fn. */
function attachSessionLog(session: AgentSession, log: SessionLog): () => void {
	return session.subscribe((event: AgentSessionEvent) => {
		if (event.type === "message_update") {
			const e = event.assistantMessageEvent;
			if (e.type === "thinking_delta") appendDelta(log, "thinking", e.delta);
			else if (e.type === "text_delta") appendDelta(log, "text", e.delta);
		} else if (event.type === "tool_execution_start") {
			pushAtomicBlock(log, "tool", `› ${summarizeToolArgs(event.toolName, event.args)}`);
		} else if (event.type === "turn_end") {
			log.openKind = undefined;
		}
	});
}

function textOnly(message: AssistantMessage | undefined): string {
	if (!message) return "";
	return message.content
		.filter((block): block is Extract<AssistantMessage["content"][number], { type: "text" }> => block.type === "text")
		.map(block => block.text)
		.join("\n")
		.trim();
}

function modelLabel(model: Model, thinking: ThinkingLevel | undefined): string {
	return `${model.provider}/${model.id}${thinking && thinking !== "off" ? ` :${thinking}` : ""}`;
}

function normalizeForCompare(text: string): string {
	return text.replace(/\s+/g, " ").trim().toLowerCase();
}

async function pickModel(ctx: ExtensionCommandContext, title: string): Promise<Model | undefined> {
	const models = ctx.models.list();
	if (models.length === 0) {
		ctx.ui.notify("No authenticated models available.", "error");
		return undefined;
	}
	const sorted = [...models].sort((a, b) => `${a.provider}/${a.id}`.localeCompare(`${b.provider}/${b.id}`));
	const labels = sorted.map(m => `${m.provider}/${m.id}  (${m.name})`);
	const chosen = await ctx.ui.select(title, labels);
	if (!chosen) return undefined;
	return sorted[labels.indexOf(chosen)];
}

async function pickThinking(
	ctx: ExtensionCommandContext,
	model: Model | undefined,
	title: string,
): Promise<ThinkingLevel | undefined> {
	const efforts = model?.thinking?.efforts;
	if (!efforts || efforts.length === 0) return undefined;
	const options: ThinkingLevel[] = ["off", ...efforts.filter(effort => THINKING_LEVELS.includes(effort))];
	const chosen = await ctx.ui.select(title, options);
	return chosen as ThinkingLevel | undefined;
}

async function collectChoice(args: string, ctx: ExtensionCommandContext): Promise<WorkReviewChoice | undefined> {
	let task = args.trim();
	if (!task) {
		const entered = await ctx.ui.editor("work-review: describe the task for the coder", "");
		task = (entered ?? "").trim();
	}
	if (!task) {
		ctx.ui.notify("work-review: no task provided, cancelled.", "warning");
		return undefined;
	}

	const coderModel = await pickModel(ctx, "work-review: coder model");
	if (!coderModel) {
		ctx.ui.notify("work-review: cancelled.", "warning");
		return undefined;
	}
	const coderThinking = await pickThinking(ctx, coderModel, "work-review: coder thinking level");

	const reviewerModel = await pickModel(ctx, "work-review: reviewer model");
	if (!reviewerModel) {
		ctx.ui.notify("work-review: cancelled.", "warning");
		return undefined;
	}
	const reviewerThinking = await pickThinking(ctx, reviewerModel, "work-review: reviewer thinking level");

	const roundsChoice = await ctx.ui.select("work-review: max coder/reviewer rounds", ROUND_OPTIONS);
	const maxRounds = Number.parseInt(roundsChoice ?? DEFAULT_ROUNDS, 10);

	return { task, coderModel, coderThinking, reviewerModel, reviewerThinking, maxRounds };
}

function buildCoderPrompt(cwd: string): string {
	return `You are the CODER in an isolated coder/reviewer workflow, working in ${cwd}.
Implement the requested change directly using your tools (read, edit, write, bash, grep, glob, ast_grep, todo).
You do not see the reviewer's reasoning — only its feedback text, delivered as your next message when it requests
changes.
When you finish a round of work, reply with a concise final text summary only: what you changed, which files, key
decisions/tradeoffs, and how you verified it (tests run, commands executed). This summary is the ONLY thing the
reviewer sees of your turn, so make it complete and self-contained. Do not ask the user questions — make reasonable
engineering decisions and note assumptions in the summary instead.`;
}

function buildReviewerPrompt(cwd: string): string {
	return `You are the REVIEWER in an isolated coder/reviewer workflow for the repository at ${cwd}.
You do not see the coder's reasoning or tool calls — only its text summary, and whatever you independently inspect
with your read-only tools (read, grep, glob, bash, ast_grep, web_search). You NEVER edit files. Never trust the
summary alone — use \`git diff\`, \`git status\`, and file reads to verify the actual change, and run tests/build
commands via bash when useful.

When you are done inspecting, call the \`submit_verdict\` tool EXACTLY ONCE as your final action:
- \`approved: true\` only if the change is fully correct and complete with nothing left to fix.
- \`approved: false\` with \`feedback\`: a bullet list of concrete, actionable issues (file/line when applicable).
  Only list issues that still need fixing — do not repeat points already resolved in a prior round.
Do not call any other tool after \`submit_verdict\`, and do not describe your verdict in plain text instead of
calling the tool — the tool call is the only thing that counts as your verdict.`;
}

/**
 * Dedicated tool for the reviewer's final verdict. A typed `approved: boolean` argument
 * cannot drift into ambiguous phrasing the way a free-text "APPROVE" reply can, which is
 * what previously let a real approval get misread as a rejection and loop forever.
 */
function buildVerdictTool(onVerdict: (verdict: Verdict) => void): CustomTool {
	return {
		name: "submit_verdict",
		label: "Submit Review Verdict",
		description:
			"Submit your final review verdict. Call this exactly once, as the very last thing you do, after " +
			"independently inspecting the repository. Do not call any other tool afterward.",
		parameters: z.object({
			approved: z.boolean().describe("true only if the change is fully correct and complete, nothing left to fix"),
			feedback: z
				.string()
				.optional()
				.describe(
					"Required when approved is false: a bullet list of concrete, actionable issues (file/line when applicable).",
				),
		}),
		approval: "read",
		async execute(_toolCallId, rawParams) {
			// The schema kernel's generic `Static<TSchema>` doesn't narrow through this factory's
			// inferred return type, so validate the two fields we actually rely on directly.
			const params = rawParams as { approved?: unknown; feedback?: unknown };
			const verdict: Verdict = {
				approved: params.approved === true,
				feedback: typeof params.feedback === "string" ? params.feedback : "",
			};
			onVerdict(verdict);
			return {
				content: [
					{
						type: "text",
						text: verdict.approved ? "Verdict recorded: approved." : "Verdict recorded: changes requested.",
					},
				],
			};
		},
	};
}

/**
 * Runs one reviewer turn and waits for its `submit_verdict` call. Nudges, then forces the
 * tool call via `toolChoice`, before falling back to a safe "unresolved" verdict — this
 * bounds retries instead of ever silently guessing a verdict from prose.
 */
async function getReviewVerdict(
	reviewer: AgentSession,
	verdictBox: { value: Verdict | undefined },
	reviewPrompt: string,
): Promise<Verdict> {
	verdictBox.value = undefined;
	await reviewer.prompt(reviewPrompt);
	if (verdictBox.value) return verdictBox.value;

	await reviewer.prompt("You did not call submit_verdict. Call it now with your verdict based on what you already found.");
	if (verdictBox.value) return verdictBox.value;

	const forcedToolChoice: ToolChoice = { type: "tool", name: "submit_verdict" };
	await reviewer.prompt("Call submit_verdict now with your verdict.", { toolChoice: forcedToolChoice });
	if (verdictBox.value) return verdictBox.value;

	return {
		approved: false,
		feedback: "(reviewer did not submit a verdict after being prompted three times; needs manual inspection)",
	};
}

// ── Split-screen transcript viewer ──────────────────────────────────────────

const BLOCK_COLOR: Record<BlockKind, ThemeColor> = {
	thinking: "thinkingText",
	text: "text",
	tool: "toolTitle",
	phase: "accent",
};

function renderLogLines(log: SessionLog, theme: Theme, width: number): string[] {
	if (log.blocks.length === 0) return [theme.fg("muted", "(nothing yet)")];
	const lines: string[] = [];
	for (const block of log.blocks) {
		const wrapped = wrapTextWithAnsi(block.text, Math.max(1, width));
		for (const w of wrapped) lines.push(theme.fg(BLOCK_COLOR[block.kind], w));
		lines.push("");
	}
	return lines;
}

function padToWidth(line: string, width: number): string {
	const pad = width - visibleWidth(line);
	return pad > 0 ? line + " ".repeat(pad) : line;
}

/**
 * Split-screen viewer: coder transcript on the left, reviewer on the right, each an
 * independently scrollable {@link ScrollView} pinned to the bottom until the user scrolls
 * up. Rebuilds from the live {@link RunHistory} on a timer while mounted, so it reflects
 * new activity without needing every individual delta to trigger a render.
 */
class SplitHistoryViewer implements Component {
	private readonly coderScroll = new ScrollView([], { height: 20, scrollbar: "auto" });
	private readonly reviewerScroll = new ScrollView([], { height: 20, scrollbar: "auto" });
	private focus: "coder" | "reviewer" = "coder";
	private readonly timer: Timer;
	private lastPaneWidth = 0;

	constructor(
		private readonly ctx: ExtensionCommandContext,
		private readonly tui: TUI,
		private readonly theme: Theme,
		private readonly run: RunHistory,
		private readonly done: (result: undefined) => void,
	) {
		this.timer = ctx.setInterval(() => {
			this.refresh(this.lastPaneWidth || 40);
			this.tui.requestRender();
		}, 300);
	}

	private refresh(paneWidth: number): void {
		this.lastPaneWidth = paneWidth;
		const coderAtBottom = this.coderScroll.getScrollOffset() >= this.coderScroll.getMaxScrollOffset();
		const reviewerAtBottom = this.reviewerScroll.getScrollOffset() >= this.reviewerScroll.getMaxScrollOffset();
		this.coderScroll.setLines(renderLogLines(this.run.coder, this.theme, paneWidth));
		this.reviewerScroll.setLines(renderLogLines(this.run.reviewer, this.theme, paneWidth));
		if (coderAtBottom) this.coderScroll.scrollToBottom();
		if (reviewerAtBottom) this.reviewerScroll.scrollToBottom();
	}

	handleInput(data: string): void {
		if (matchesKey(data, "escape") || data === "q") {
			this.done(undefined);
			return;
		}
		if (matchesKey(data, "tab")) {
			this.focus = this.focus === "coder" ? "reviewer" : "coder";
			return;
		}
		const target = this.focus === "coder" ? this.coderScroll : this.reviewerScroll;
		target.handleScrollKey(data);
	}

	dispose(): void {
		this.ctx.clearTimer(this.timer);
	}

	render(width: number): readonly string[] {
		const rows = this.tui.terminal.rows ?? 24;
		const height = Math.max(6, rows - 6);
		this.coderScroll.setHeight(height);
		this.reviewerScroll.setHeight(height);

		const paneWidth = Math.max(20, Math.floor((width - 3) / 2));
		if (paneWidth !== this.lastPaneWidth) this.refresh(paneWidth);

		const coderHeader = `${this.focus === "coder" ? "▶ " : "  "}CODER — ${this.run.coderLabel}`;
		const reviewerHeader = `${this.focus === "reviewer" ? "▶ " : "  "}REVIEWER — ${this.run.reviewerLabel}`;
		const headerLine = `${padToWidth(this.theme.fg("accent", coderHeader), paneWidth)} │ ${this.theme.fg("accent", reviewerHeader)}`;

		const left = this.coderScroll.render(paneWidth);
		const right = this.reviewerScroll.render(paneWidth);
		const bodyRows = Math.max(left.length, right.length);
		const out: string[] = [headerLine];
		for (let i = 0; i < bodyRows; i++) {
			out.push(`${padToWidth(left[i] ?? "", paneWidth)} │ ${right[i] ?? ""}`);
		}
		out.push(
			this.theme.fg(
				"muted",
				`status: ${this.run.status}   ·   ↑/↓ scroll   Tab switch pane (${this.focus})   Home/End jump   Esc close`,
			),
		);
		return out;
	}
}

async function runLoop(pi: ExtensionAPI, ctx: ExtensionCommandContext, choice: WorkReviewChoice): Promise<void> {
	const run: RunHistory = {
		task: choice.task,
		coderLabel: modelLabel(choice.coderModel, choice.coderThinking),
		reviewerLabel: modelLabel(choice.reviewerModel, choice.reviewerThinking),
		coder: createSessionLog(),
		reviewer: createSessionLog(),
		status: "starting…",
	};
	activeRun = run;

	const settings = Settings.isolated({
		"tools.approvalMode": "yolo",
		"compaction.enabled": true,
		"retry.enabled": true,
	});

	const verdictBox: { value: Verdict | undefined } = { value: undefined };
	const verdictTool = buildVerdictTool(v => {
		verdictBox.value = v;
	});

	const [coder, reviewer] = await Promise.all([
		createAgentSession({
			cwd: ctx.cwd,
			agentRegistry: new AgentRegistry(),
			modelRegistry: ctx.modelRegistry,
			model: choice.coderModel,
			thinkingLevel: choice.coderThinking,
			sessionManager: SessionManager.inMemory(),
			settings,
			toolNames: CODER_TOOLS,
			restrictToolNames: true,
			disableExtensionDiscovery: true,
			appendSystemPrompt: buildCoderPrompt(ctx.cwd),
		}),
		createAgentSession({
			cwd: ctx.cwd,
			agentRegistry: new AgentRegistry(),
			modelRegistry: ctx.modelRegistry,
			model: choice.reviewerModel,
			thinkingLevel: choice.reviewerThinking,
			sessionManager: SessionManager.inMemory(),
			settings,
			toolNames: REVIEWER_TOOLS,
			restrictToolNames: true,
			allowRestrictedCustomTools: true,
			customTools: [verdictTool],
			disableExtensionDiscovery: true,
			appendSystemPrompt: buildReviewerPrompt(ctx.cwd),
		}),
	]);

	const unsubCoder = attachSessionLog(coder.session, run.coder);
	const unsubReviewer = attachSessionLog(reviewer.session, run.reviewer);

	const rounds: RoundEntry[] = [];
	let approved = false;
	let stalled = false;
	let previousFeedback: string | undefined;

	try {
		let coderPrompt = choice.task;

		for (let round = 1; round <= choice.maxRounds; round++) {
			run.status = `round ${round}/${choice.maxRounds}: coding`;
			ctx.ui.setStatus("work-review", run.status);
			pushAtomicBlock(run.coder, "phase", `── Round ${round}/${choice.maxRounds}: implementing ──`);

			await coder.session.prompt(coderPrompt);
			const coderSummary = textOnly(coder.session.getLastAssistantMessage()) || "(coder returned no text summary)";

			run.status = `round ${round}/${choice.maxRounds}: reviewing`;
			ctx.ui.setStatus("work-review", run.status);
			pushAtomicBlock(run.reviewer, "phase", `── Round ${round}/${choice.maxRounds}: reviewing ──`);

			const reviewPrompt =
				round === 1
					? `Original task:\n${choice.task}\n\nCoder's summary of its changes:\n${coderSummary}\n\nReview the actual repository state now.`
					: `Coder's summary of changes made to address your last feedback:\n${coderSummary}\n\nReview the actual repository state now.`;
			const verdict = await getReviewVerdict(reviewer.session, verdictBox, reviewPrompt);
			rounds.push({ round, coderSummary, approved: verdict.approved, feedback: verdict.feedback });

			if (verdict.approved) {
				approved = true;
				ctx.ui.notify(`work-review: reviewer approved after round ${round}.`, "info");
				break;
			}

			if (round === choice.maxRounds) {
				ctx.ui.notify(`work-review: round cap (${choice.maxRounds}) reached without approval.`, "warning");
				break;
			}

			if (previousFeedback !== undefined && normalizeForCompare(verdict.feedback) === normalizeForCompare(previousFeedback)) {
				stalled = true;
				ctx.ui.notify("work-review: reviewer repeated identical feedback — stopping early (stalled).", "warning");
				break;
			}
			previousFeedback = verdict.feedback;

			coderPrompt = `Reviewer feedback — address every point:\n${verdict.feedback}`;
		}
	} finally {
		unsubCoder();
		unsubReviewer();
		run.status = approved ? "approved" : stalled ? "stalled" : "round cap reached";
		ctx.ui.setStatus("work-review", undefined);
		await Promise.allSettled([coder.session.dispose(), reviewer.session.dispose()]);
	}

	const outcome = approved ? "— approved ✅" : stalled ? "— stalled ⚠️" : "— round cap reached ⚠️";
	const header = `## /work-review ${outcome}
**Task:** ${choice.task}
**Coder:** ${modelLabel(choice.coderModel, choice.coderThinking)}
**Reviewer:** ${modelLabel(choice.reviewerModel, choice.reviewerThinking)}
**Rounds run:** ${rounds.length}/${choice.maxRounds}
${approved ? "" : "\nChanges from the last round remain in the working tree. Run `git diff` to inspect them; re-run /work-review to continue iterating."}
Full live/scrollable transcript: run \`/work-review-view\`.`;

	const roundLog = rounds
		.map(
			r =>
				`### Round ${r.round}\n**Coder:**\n${r.coderSummary}\n\n**Reviewer:** ${r.approved ? "APPROVE" : "REQUEST_CHANGES"}\n${r.approved ? "" : r.feedback}`,
		)
		.join("\n\n");

	pi.sendMessage(
		{
			customType: "work-review-result",
			content: `${header}\n\n${roundLog}`,
			display: true,
		},
		{ triggerTurn: false },
	);
}

/**
 * Opens the split viewer for the active run. `ctx.ui.custom` is a documented no-op in
 * non-TUI modes (RPC/print) — it resolves immediately without throwing — so this needs
 * no mode check; there is no `ctx.mode` field on `ExtensionContext` to check against.
 */
async function openHistoryViewer(ctx: ExtensionCommandContext): Promise<void> {
	if (!activeRun) {
		ctx.ui.notify("work-review-view: no work-review run yet — start one with /work-review.", "warning");
		return;
	}
	const run = activeRun;
	await ctx.ui.custom<undefined>(
		(tui, theme, _keybindings, done) => new SplitHistoryViewer(ctx, tui, theme, run, done),
		{ overlay: true },
	);
}

export default function workReviewExtension(pi: ExtensionAPI) {
	pi.setLabel("Work + Review Loop");

	pi.registerCommand("work-review", {
		description: "Coder → reviewer loop: isolated contexts, pick model + thinking level for each",
		handler: async (args, ctx) => {
			if (!ctx.hasUI) {
				ctx.ui.notify("work-review requires interactive dialogs (TUI or RPC mode).", "error");
				return;
			}

			const choice = await collectChoice(args, ctx);
			if (!choice) return;

			ctx.ui.notify(
				`work-review: starting — coder=${modelLabel(choice.coderModel, choice.coderThinking)}, reviewer=${modelLabel(
					choice.reviewerModel,
					choice.reviewerThinking,
				)}, max ${choice.maxRounds} round(s).`,
				"info",
			);

			// `activeRun` is set synchronously at the top of runLoop, before its first
			// await, so it is already populated by the time this line finishes — safe to
			// open the viewer right after. The loop keeps running in the background while
			// the viewer is open, and after Esc closes it, and after this handler returns.
			const runPromise = runLoop(pi, ctx, choice).catch(err => {
				ctx.ui.notify(`work-review failed: ${err instanceof Error ? err.message : String(err)}`, "error");
			});

			await openHistoryViewer(ctx);
			await runPromise;
		},
	});

	pi.registerCommand("work-review-view", {
		description: "Reopen the split coder/reviewer transcript viewer for the current or last work-review run",
		handler: async (_args, ctx) => {
			await openHistoryViewer(ctx);
		},
	});
}
