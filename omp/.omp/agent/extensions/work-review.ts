/**
 * /work-review — isolated coder → reviewer loop with a live activity view.
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
 * (a boolean + optional feedback string), not by regex-matching its free-text reply.
 * Free text drifts under repeated rounds ("looks fine", "nothing left to do", markdown
 * formatting, etc.) and a text-based parser can silently misclassify a real approval as
 * a rejection, which then bounces the coder into a "nothing to do" / reviewer "still ok"
 * loop that never terminates. A tool call with a typed `approved: boolean` argument
 * cannot drift that way — the model must produce a boolean, not a string we guess at.
 *
 * The two sessions loop (coder implements → reviewer reviews → coder addresses
 * feedback → …) until the reviewer approves, a round cap is hit, or feedback stalls
 * (two rounds in a row with identical feedback — no further progress is happening).
 * Both sessions keep their own multi-turn history across rounds for continuity without
 * cross-contaminating each other's context.
 *
 * While the loop runs, each session's live thinking/text/tool activity streams into
 * its own always-visible widget (`work-review-coder` / `work-review-reviewer`), so the
 * actual reasoning trace of both agents is visible on screen in real time — never
 * relayed to the *other* agent, only surfaced to the human watching.
 */
import type { ThinkingLevel } from "@oh-my-pi/pi-agent-core";
import type {
	AgentSession,
	AgentSessionEvent,
	CustomTool,
	ExtensionAPI,
	ExtensionCommandContext,
} from "@oh-my-pi/pi-coding-agent";
import { AgentRegistry, createAgentSession, SessionManager, Settings, z } from "@oh-my-pi/pi-coding-agent";
import type { AssistantMessage, Model, ToolChoice } from "@oh-my-pi/pi-ai";

// Tool split is the actual isolation/safety boundary for the reviewer: it can run
// tests/greps/reads but has no edit/write/ast_edit access.
const CODER_TOOLS = ["read", "edit", "write", "bash", "grep", "glob", "ast_grep", "todo"];
const REVIEWER_TOOLS = ["read", "grep", "glob", "bash", "ast_grep", "web_search", "submit_verdict"];

const THINKING_LEVELS: readonly ThinkingLevel[] = ["off", "minimal", "low", "medium", "high", "xhigh", "max"];
const ROUND_OPTIONS = ["3", "5", "8", "12"];
const DEFAULT_ROUNDS = "5";

// Widget line budget (setWidget content is capped at 10 lines): 1 header + this many tail lines.
const WIDGET_TAIL_LINES = 8;
const WIDGET_LINE_WIDTH = 100;
// Bound how much raw streamed text we keep around per turn; only the tail is ever shown.
const MAX_BUFFER_CHARS = 8000;

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

/** Best-effort single-line description of a tool call, for the live activity view. */
function summarizeToolArgs(toolName: string, args: unknown): string {
	if (args && typeof args === "object") {
		const a = args as Record<string, unknown>;
		const candidate = a.command ?? a.path ?? a.pattern ?? a.query ?? a.url;
		if (typeof candidate === "string") return `${toolName}: ${candidate}`;
		if (toolName === "submit_verdict" && typeof a.approved === "boolean") return `submit_verdict: approved=${a.approved}`;
	}
	return toolName;
}

function wrapTail(text: string, width: number, maxLines: number): string[] {
	const clean = text.replace(/\s+/g, " ").trim();
	if (!clean) return [];
	const lines: string[] = [];
	for (let i = 0; i < clean.length; i += width) lines.push(clean.slice(i, i + width));
	return lines.slice(-maxLines);
}

/**
 * Streams one child session's live activity (thinking, text, tool calls) into its own
 * always-visible widget so the human watching can see exactly what that agent is doing,
 * in real time, without that trace ever being relayed to the other agent.
 */
function createLiveTracker(ctx: ExtensionCommandContext, widgetKey: string, role: string) {
	let phase = "starting…";
	let activity = "idle";
	let thinkingBuf = "";
	let textBuf = "";
	let toolLine = "";
	let dirty = true;
	let lastRendered = "";

	const render = () => {
		const header = `${role} — ${phase} — ${activity}`;
		const source = activity.startsWith("running")
			? toolLine
			: activity.startsWith("writing")
				? textBuf
				: thinkingBuf || textBuf || toolLine;
		const lines = [header, ...wrapTail(source, WIDGET_LINE_WIDTH, WIDGET_TAIL_LINES)];
		const rendered = lines.join("\n");
		if (rendered === lastRendered) return;
		lastRendered = rendered;
		ctx.ui.setWidget(widgetKey, lines);
	};

	const timer = ctx.setInterval(() => {
		if (dirty) {
			dirty = false;
			render();
		}
	}, 250);

	const handleEvent = (event: AgentSessionEvent): void => {
		if (event.type === "message_update") {
			const e = event.assistantMessageEvent;
			if (e.type === "thinking_delta") {
				activity = "thinking…";
				thinkingBuf = (thinkingBuf + e.delta).slice(-MAX_BUFFER_CHARS);
				dirty = true;
			} else if (e.type === "text_delta") {
				activity = "writing…";
				textBuf = (textBuf + e.delta).slice(-MAX_BUFFER_CHARS);
				dirty = true;
			}
		} else if (event.type === "tool_execution_start") {
			activity = `running ${event.toolName}`;
			toolLine = summarizeToolArgs(event.toolName, event.args);
			dirty = true;
		} else if (event.type === "tool_execution_end") {
			activity = event.isError ? `${event.toolName} failed` : "thinking…";
			dirty = true;
		} else if (event.type === "turn_end") {
			activity = "waiting…";
			dirty = true;
		}
	};

	return {
		attach(session: { subscribe: (l: (e: AgentSessionEvent) => void) => () => void }): () => void {
			return session.subscribe(handleEvent);
		},
		setPhase(next: string): void {
			phase = next;
			activity = "starting…";
			dirty = true;
		},
		resetTurn(): void {
			thinkingBuf = "";
			textBuf = "";
			toolLine = "";
		},
		dispose(): void {
			ctx.clearTimer(timer);
			ctx.ui.setWidget(widgetKey, undefined);
		},
	};
}

async function runLoop(pi: ExtensionAPI, ctx: ExtensionCommandContext, choice: WorkReviewChoice): Promise<void> {
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

	const coderView = createLiveTracker(ctx, "work-review-coder", "CODER");
	const reviewerView = createLiveTracker(ctx, "work-review-reviewer", "REVIEWER");
	const unsubCoder = coderView.attach(coder.session);
	const unsubReviewer = reviewerView.attach(reviewer.session);

	const rounds: RoundEntry[] = [];
	let approved = false;
	let stalled = false;
	let previousFeedback: string | undefined;

	try {
		let coderPrompt = choice.task;

		for (let round = 1; round <= choice.maxRounds; round++) {
			ctx.ui.setStatus("work-review", `round ${round}/${choice.maxRounds}: coding`);
			coderView.setPhase(`round ${round}/${choice.maxRounds} — implementing`);
			coderView.resetTurn();

			await coder.session.prompt(coderPrompt);
			const coderSummary = textOnly(coder.session.getLastAssistantMessage()) || "(coder returned no text summary)";

			ctx.ui.setStatus("work-review", `round ${round}/${choice.maxRounds}: reviewing`);
			reviewerView.setPhase(`round ${round}/${choice.maxRounds} — reviewing`);
			reviewerView.resetTurn();

			const reviewPrompt =
				round === 1
					? `Original task:\n${choice.task}\n\nCoder's summary of its changes:\n${coderSummary}\n\nReview the actual repository state now.`
					: `Coder's summary of changes made to address your last feedback:\n${coderSummary}\n\nReview the actual repository state now.`;
			const verdict = await getReviewVerdict(reviewer.session, verdictBox, reviewPrompt);
			rounds.push({ round, coderSummary, approved: verdict.approved, feedback: verdict.feedback });

			if (verdict.approved) {
				approved = true;
				coderView.setPhase(`round ${round}/${choice.maxRounds} — approved`);
				reviewerView.setPhase(`round ${round}/${choice.maxRounds} — approved`);
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
		coderView.dispose();
		reviewerView.dispose();
		ctx.ui.setStatus("work-review", undefined);
		await Promise.allSettled([coder.session.dispose(), reviewer.session.dispose()]);
	}

	const outcome = approved ? "— approved ✅" : stalled ? "— stalled ⚠️" : "— round cap reached ⚠️";
	const header = `## /work-review ${outcome}
**Task:** ${choice.task}
**Coder:** ${modelLabel(choice.coderModel, choice.coderThinking)}
**Reviewer:** ${modelLabel(choice.reviewerModel, choice.reviewerThinking)}
**Rounds run:** ${rounds.length}/${choice.maxRounds}
${approved ? "" : "\nChanges from the last round remain in the working tree. Run `git diff` to inspect them; re-run /work-review to continue iterating."}`;

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

export default function workReviewExtension(pi: ExtensionAPI) {
	pi.setLabel("Work + Review Loop");

	pi.registerCommand("work-review", {
		description: "Coder → reviewer loop: isolated contexts, live thinking trace, pick model + thinking level for each",
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

			try {
				await runLoop(pi, ctx, choice);
			} catch (err) {
				ctx.ui.notify(`work-review failed: ${err instanceof Error ? err.message : String(err)}`, "error");
			}
		},
	});
}
