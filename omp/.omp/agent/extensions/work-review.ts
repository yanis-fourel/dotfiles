/**
 * /work-review — isolated coder → reviewer loop where the MAIN interactive session
 * literally becomes each agent in turn, instead of opening a split view.
 *
 * Isolation is still enforced by code, not prompt discipline — coder and reviewer are
 * two independent, disk-backed sessions (own message history, own tools, own model):
 *
 *  - The coder session gets real read/write/exec tools scoped to the project cwd and
 *    implements the requested change directly in the working tree.
 *  - The reviewer session gets read-only tools and never sees the coder's thinking,
 *    tool calls, or intermediate turns — only the coder's final text summary plus
 *    whatever it independently reads from the repository.
 *  - The coder never sees the reviewer's thinking either — only the reviewer's final
 *    feedback text, fed back as the next prompt.
 *
 * The reviewer's verdict is captured through a dedicated `work_review_submit_verdict`
 * tool call (a boolean + optional feedback string), not by regex-matching its free-text
 * reply — a typed boolean can't drift into ambiguous phrasing the way "APPROVE" in
 * prose can.
 *
 * UI: rather than rendering a synthetic transcript in a custom split-screen overlay,
 * `/work-review` drives the SAME `AgentSession` that powers the interactive terminal —
 * `ctx.switchSession()` repoints it at the coder's session file while the coder works,
 * then at the reviewer's while it reviews. While a given agent is "on stage" every
 * native affordance just works: live streaming, thinking/tool-call rendering, tool
 * approval prompts, Esc-to-interrupt, and typing a follow-up into the input box (native
 * steer/resume) — none of that is reimplemented here.
 *
 * Consequences worth knowing:
 *  - This is modal: your own conversation is off-screen for the run's duration (that's
 *    the point — the terminal "becomes" the worker, then the reviewer). It's restored
 *    automatically when the run ends, or via `/work-review-stop`.
 *  - `switchSession` only happens between rounds (never while a turn is mid-stream), so
 *    this models coder/reviewer as strictly serial — they're never watched simultaneously.
 *    Genuine simultaneous native views would mean spawning separate `omp --resume <file>`
 *    processes (e.g. in tmux panes) instead of one process taking turns.
 *  - Tool approval mode is inherited from your own session's settings (there is no
 *    extension-facing API to force yolo-mode on a sub-scope). If you want the coder and
 *    reviewer to run unattended, start this session with `--approval-mode yolo` (or set
 *    `tools.approvalMode` accordingly) — otherwise you'll see normal approval prompts
 *    while each is on stage, which is also a legitimate way to supervise them live.
 *  - The coder/reviewer sessions are real, persisted session files — `/work-review-peek`
 *    gives a quick read of the latest output without switching onto them, and
 *    `/resume <file>` (path printed in the final summary) opens either one's full native
 *    history at any time, no bespoke viewer needed.
 */
import type { AgentMessage, ThinkingLevel } from "@oh-my-pi/pi-agent-core";
import type { ExtensionAPI, ExtensionCommandContext } from "@oh-my-pi/pi-coding-agent";
import { z } from "@oh-my-pi/pi-coding-agent";
import type { AssistantMessage, Model } from "@oh-my-pi/pi-ai";
import { matchesKey, ScrollView, wrapTextWithAnsi } from "@oh-my-pi/pi-tui";

// Tool split is the actual isolation/safety boundary for the reviewer: it can run
// tests/greps/reads but has no edit/write/ast_edit access.
const CODER_TOOLS = ["read", "edit", "write", "bash", "grep", "glob", "ast_grep", "todo"];
const REVIEWER_TOOLS = ["read", "grep", "glob", "bash", "ast_grep", "web_search"];
const VERDICT_TOOL_NAME = "work_review_submit_verdict";

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

type WorkReviewMode = "coder" | "reviewer";

/** Freeze switch for one `/work-review` run: pauses the round loop between turns without
 *  touching anything else in the process (unlike the SDK's process-wide `AgentPauseGate`,
 *  which would also freeze the user's own session). */
class RunGate {
	#gate: { promise: Promise<void>; resolve: () => void } | undefined;

	get paused(): boolean {
		return this.#gate !== undefined;
	}

	pause(): void {
		if (this.#gate) return;
		let resolve!: () => void;
		const promise = new Promise<void>(r => {
			resolve = r;
		});
		this.#gate = { promise, resolve };
	}

	resume(): void {
		this.#gate?.resolve();
		this.#gate = undefined;
	}

	wait(): Promise<void> {
		return this.#gate?.promise ?? Promise.resolve();
	}
}

/** State for the single `/work-review` run this extension instance can drive at once. */
interface RunState {
	task: string;
	coderModel: Model;
	coderThinking: ThinkingLevel | undefined;
	reviewerModel: Model;
	reviewerThinking: ThinkingLevel | undefined;
	maxRounds: number;
	/** The user's own session file, restored when the run ends. */
	originalFile: string;
	coderFile: string;
	reviewerFile: string;
	/** Which agent's system prompt/tools should be in effect for the NEXT turn. */
	mode: WorkReviewMode | undefined;
	lastAssistantText: { coder?: string; reviewer?: string };
	verdictBox: Verdict | undefined;
	pendingTurn: { resolve: () => void; reject: (err: Error) => void } | undefined;
	cancelled: boolean;
	gate: RunGate;
	status: string;
	/** Set once `runLoop` returns, so a stale run never blocks the next `/work-review`. */
	done: boolean;
}

function isAssistantMessage(message: AgentMessage): message is AssistantMessage {
	return message.role === "assistant";
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

When you are done inspecting, call the \`${VERDICT_TOOL_NAME}\` tool EXACTLY ONCE as your final action:
- \`approved: true\` only if the change is fully correct and complete with nothing left to fix.
- \`approved: false\` with \`feedback\`: a bullet list of concrete, actionable issues (file/line when applicable).
  Only list issues that still need fixing — do not repeat points already resolved in a prior round.
Do not call any other tool after \`${VERDICT_TOOL_NAME}\`, and do not describe your verdict in plain text instead of
calling the tool — the tool call is the only thing that counts as your verdict.`;
}

/** Runtime-validated shape of the verdict tool's arguments — reused for both the tool's
 *  declared parameter schema and to actually validate what the model sent, since tool
 *  arguments are external input the compiler never verified. */
const VerdictParamsSchema = z.object({
	approved: z.boolean().describe("true only if the change is fully correct and complete, nothing left to fix"),
	feedback: z
		.string()
		.optional()
		.describe(
			"Required when approved is false: a bullet list of concrete, actionable issues (file/line when applicable).",
		),
});

/**
 * Registered once at extension load. `defaultInactive` keeps it invisible to every
 * session (including the coder's) until `enterMode` explicitly activates it while the
 * reviewer is on stage — the coder can never call it, by construction, not by prompt.
 */
function registerVerdictTool(pi: ExtensionAPI, onVerdict: (verdict: Verdict) => void): void {
	pi.registerTool({
		name: VERDICT_TOOL_NAME,
		label: "Submit Review Verdict",
		description:
			"Submit your final review verdict. Call this exactly once, as the very last thing you do, after " +
			"independently inspecting the repository. Do not call any other tool afterward.",
		parameters: VerdictParamsSchema,
		approval: "read",
		defaultInactive: true,
		async execute(_toolCallId, rawParams) {
			const parsed = VerdictParamsSchema.safeParse(rawParams);
			const verdict: Verdict = parsed.success
				? { approved: parsed.data.approved, feedback: parsed.data.feedback ?? "" }
				: { approved: false, feedback: "" };
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
	});
}

/** Sends `text` as the next user turn and resolves once that turn's `agent_end` settles
 *  (or rejects if `/work-review-stop`/`/work-review-pause` cuts it short — see the
 *  `agent_end`/pause/stop wiring in the extension body). `pi.sendUserMessage` itself is
 *  fire-and-forget and races several internal `await`s before `isStreaming` flips, so
 *  polling `ctx.waitForIdle()` right after calling it is NOT safe — this event-driven
 *  handshake is. */
function runTurn(pi: ExtensionAPI, run: RunState, text: string): Promise<void> {
	return new Promise<void>((resolve, reject) => {
		run.pendingTurn = { resolve, reject };
		pi.sendUserMessage(text);
	});
}

/** Points the main session at the right file/tools/model for `mode`, only switching the
 *  session file when necessary (round 1 coder turn is already there). Returns false when
 *  a hook cancelled the switch or no credentials are available for the target model —
 *  callers treat that as "stop the run". */
async function enterMode(
	pi: ExtensionAPI,
	ctx: ExtensionCommandContext,
	run: RunState,
	mode: WorkReviewMode,
): Promise<boolean> {
	const file = mode === "coder" ? run.coderFile : run.reviewerFile;
	if (ctx.sessionManager.getSessionFile() !== file) {
		const { cancelled } = await ctx.switchSession(file);
		if (cancelled) return false;
	}
	run.mode = mode;
	const tools = mode === "coder" ? CODER_TOOLS : [...REVIEWER_TOOLS, VERDICT_TOOL_NAME];
	await pi.setActiveTools(tools);
	const model = mode === "coder" ? run.coderModel : run.reviewerModel;
	const modelOk = await pi.setModel(model);
	if (!modelOk) {
		ctx.ui.notify(`work-review: no credentials available for ${modelLabel(model, undefined)}.`, "error");
		return false;
	}
	const thinking = mode === "coder" ? run.coderThinking : run.reviewerThinking;
	if (thinking) pi.setThinkingLevel(thinking);
	return true;
}

/**
 * Runs one reviewer turn and waits for its `work_review_submit_verdict` call. Nudges up
 * to twice more before falling back to a safe "unresolved" verdict — this bounds retries
 * instead of ever silently guessing a verdict from prose. Unlike the in-process design
 * this replaces, there is no extension-facing way to force a tool choice on a turn, so
 * the nudges are plain text rather than a forced `toolChoice`.
 */
async function getReviewVerdict(
	pi: ExtensionAPI,
	run: RunState,
	reviewPrompt: string,
): Promise<Verdict | "cancelled"> {
	run.verdictBox = undefined;
	const nudges = [
		reviewPrompt,
		"You did not call the verdict tool. Call it now with your verdict based on what you already found.",
		`This is your final chance: call ${VERDICT_TOOL_NAME} now with your verdict, and nothing else.`,
	];
	for (const prompt of nudges) {
		try {
			await runTurn(pi, run, prompt);
		} catch {
			return "cancelled";
		}
		if (run.cancelled) return "cancelled";
		if (run.verdictBox) return run.verdictBox;
	}
	return {
		approved: false,
		feedback: "(reviewer did not submit a verdict after being prompted three times; needs manual inspection)",
	};
}

async function runLoop(pi: ExtensionAPI, ctx: ExtensionCommandContext, run: RunState): Promise<void> {
	const rounds: RoundEntry[] = [];
	let approved = false;
	let stalled = false;
	let cancelledOut = false;
	let previousFeedback: string | undefined;

	try {
		let coderPrompt = run.task;

		roundLoop: for (let round = 1; round <= run.maxRounds; round++) {
			await run.gate.wait();
			if (run.cancelled) {
				cancelledOut = true;
				break;
			}

			run.status = `round ${round}/${run.maxRounds}: coding`;
			ctx.ui.setStatus("work-review", run.status);
			ctx.ui.setTitle(`🔨 coder · work-review ${round}/${run.maxRounds}`);
			if (!(await enterMode(pi, ctx, run, "coder"))) {
				cancelledOut = true;
				break;
			}

			try {
				await runTurn(pi, run, coderPrompt);
			} catch {
				cancelledOut = true;
				break;
			}

			await run.gate.wait();
			if (run.cancelled) {
				cancelledOut = true;
				break;
			}

			const coderSummary = run.lastAssistantText.coder || "(coder returned no text summary)";

			run.status = `round ${round}/${run.maxRounds}: reviewing`;
			ctx.ui.setStatus("work-review", run.status);
			ctx.ui.setTitle(`🔍 reviewer · work-review ${round}/${run.maxRounds}`);
			if (!(await enterMode(pi, ctx, run, "reviewer"))) {
				cancelledOut = true;
				break;
			}

			const reviewPrompt =
				round === 1
					? `Original task:\n${run.task}\n\nCoder's summary of its changes:\n${coderSummary}\n\nReview the actual repository state now.`
					: `Coder's summary of changes made to address your last feedback:\n${coderSummary}\n\nReview the actual repository state now.`;
			const verdict = await getReviewVerdict(pi, run, reviewPrompt);
			if (verdict === "cancelled") {
				cancelledOut = true;
				break;
			}
			rounds.push({ round, coderSummary, approved: verdict.approved, feedback: verdict.feedback });

			if (verdict.approved) {
				approved = true;
				ctx.ui.notify(`work-review: reviewer approved after round ${round}.`, "info");
				break roundLoop;
			}

			if (round === run.maxRounds) {
				ctx.ui.notify(`work-review: round cap (${run.maxRounds}) reached without approval.`, "warning");
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
		run.mode = undefined;
		ctx.ui.setStatus("work-review", undefined);
		ctx.ui.setTitle(ctx.cwd.split("/").pop() ?? "omp");
		if (ctx.sessionManager.getSessionFile() !== run.originalFile) {
			const { cancelled } = await ctx.switchSession(run.originalFile);
			if (cancelled) {
				ctx.ui.notify(
					`work-review: could not restore your session automatically — resume it with "/resume ${run.originalFile}".`,
					"warning",
				);
			}
		}
		run.done = true;
	}

	const outcome = cancelledOut
		? "— interrupted 🛑"
		: approved
			? "— approved ✅"
			: stalled
				? "— stalled ⚠️"
				: "— round cap reached ⚠️";
	const header = `## /work-review ${outcome}
**Task:** ${run.task}
**Coder:** ${modelLabel(run.coderModel, run.coderThinking)} — session: \`${run.coderFile}\`
**Reviewer:** ${modelLabel(run.reviewerModel, run.reviewerThinking)} — session: \`${run.reviewerFile}\`
**Rounds run:** ${rounds.length}/${run.maxRounds}
${approved || cancelledOut ? "" : "\nChanges from the last round remain in the working tree. Run `git diff` to inspect them; re-run /work-review to continue iterating."}
Inspect either agent's full native history any time with \`/resume <session>\`, or a quick snapshot with \`/work-review-peek coder\` / \`/work-review-peek reviewer\`.`;

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

	/** The run this extension instance is driving, if any. A new `/work-review` refuses
	 *  to start while a previous one hasn't reached its `finally` block yet. */
	let run: RunState | undefined;

	registerVerdictTool(pi, verdict => {
		if (run) run.verdictBox = verdict;
	});

	// Re-injects the coder/reviewer role prompt on top of the session's normal base
	// system prompt for every turn taken while that role is on stage. Additive (appends
	// to `event.systemPrompt`, doesn't replace it) so tool-use instructions and workspace
	// info the host already computed stay intact.
	pi.on("before_agent_start", (event, ctx) => {
		if (!run?.mode) return;
		const addendum = run.mode === "coder" ? buildCoderPrompt(ctx.cwd) : buildReviewerPrompt(ctx.cwd);
		return { systemPrompt: [...event.systemPrompt, addendum] };
	});

	// Single always-on listener replaces the old per-child `session.subscribe` plumbing:
	// there's only one real session now, so this sees every turn coder/reviewer ever run.
	pi.on("agent_end", event => {
		if (!run?.mode) return;
		const lastAssistant = [...event.messages].reverse().find(isAssistantMessage);
		if (lastAssistant) run.lastAssistantText[run.mode] = textOnly(lastAssistant);
		if (event.willContinue) return;
		const pending = run.pendingTurn;
		if (pending) {
			run.pendingTurn = undefined;
			pending.resolve();
		}
	});

	pi.registerCommand("work-review", {
		description: "Coder → reviewer loop: the main session becomes the coder, then the reviewer, in turn",
		handler: async (args, ctx) => {
			if (!ctx.hasUI) {
				ctx.ui.notify("work-review requires interactive dialogs (TUI or RPC mode).", "error");
				return;
			}
			if (run && !run.done) {
				ctx.ui.notify("work-review: a run is already in progress. Use /work-review-stop first.", "warning");
				return;
			}

			const originalFile = ctx.sessionManager.getSessionFile();
			if (!originalFile) {
				ctx.ui.notify(
					"work-review needs a persisted session to switch back to — this session was started with --no-session.",
					"error",
				);
				return;
			}

			const choice = await collectChoice(args, ctx);
			if (!choice) return;

			const coderCreated = await ctx.newSession();
			if (coderCreated.cancelled) {
				ctx.ui.notify("work-review: cancelled.", "warning");
				return;
			}
			const coderFile = ctx.sessionManager.getSessionFile();
			if (!coderFile) {
				ctx.ui.notify("work-review: failed to create the coder session.", "error");
				await ctx.switchSession(originalFile);
				return;
			}

			const reviewerCreated = await ctx.newSession();
			if (reviewerCreated.cancelled) {
				ctx.ui.notify("work-review: cancelled.", "warning");
				await ctx.switchSession(originalFile);
				return;
			}
			const reviewerFile = ctx.sessionManager.getSessionFile();
			if (!reviewerFile) {
				ctx.ui.notify("work-review: failed to create the reviewer session.", "error");
				await ctx.switchSession(originalFile);
				return;
			}

			run = {
				task: choice.task,
				coderModel: choice.coderModel,
				coderThinking: choice.coderThinking,
				reviewerModel: choice.reviewerModel,
				reviewerThinking: choice.reviewerThinking,
				maxRounds: choice.maxRounds,
				originalFile,
				coderFile,
				reviewerFile,
				mode: undefined,
				lastAssistantText: {},
				verdictBox: undefined,
				pendingTurn: undefined,
				cancelled: false,
				gate: new RunGate(),
				status: "starting…",
				done: false,
			};

			ctx.ui.notify(
				`work-review: starting — coder=${modelLabel(choice.coderModel, choice.coderThinking)}, reviewer=${modelLabel(
					choice.reviewerModel,
					choice.reviewerThinking,
				)}, max ${choice.maxRounds} round(s). This session will become each agent in turn: Esc interrupts whichever ` +
					"is on stage, /work-review-pause + /work-review-resume freeze the workflow between turns, /work-review-stop ends the run.",
				"info",
			);

			await runLoop(pi, ctx, run);
		},
	});

	pi.registerCommand("work-review-pause", {
		description: "Pause the active /work-review run: interrupts whoever is on stage and freezes the workflow",
		handler: async (_args, ctx) => {
			if (!run || run.done) {
				ctx.ui.notify("work-review-pause: no active run.", "warning");
				return;
			}
			if (run.gate.paused) {
				ctx.ui.notify("work-review-pause: already paused.", "warning");
				return;
			}
			run.gate.pause();
			ctx.abort();
			// Don't wait on agent_end to notice the abort — resolve the in-flight turn
			// immediately so the round loop reaches the gate and parks there right away.
			const pending = run.pendingTurn;
			if (pending) {
				run.pendingTurn = undefined;
				pending.resolve();
			}
			ctx.ui.setStatus("work-review", `${run.status} · paused`);
			ctx.ui.notify(
				`work-review: paused. You're talking directly to the ${run.mode ?? "active"} session now — type below, or /work-review-resume to continue the workflow.`,
				"info",
			);
		},
	});

	pi.registerCommand("work-review-resume", {
		description: "Resume a /work-review run paused with /work-review-pause",
		handler: async (_args, ctx) => {
			if (!run || run.done) {
				ctx.ui.notify("work-review-resume: no active run.", "warning");
				return;
			}
			if (!run.gate.paused) {
				ctx.ui.notify("work-review-resume: run is not paused.", "warning");
				return;
			}
			run.gate.resume();
			ctx.ui.setStatus("work-review", run.status);
			ctx.ui.notify("work-review: resumed.", "info");
		},
	});

	pi.registerCommand("work-review-stop", {
		description: "Interrupt the entire /work-review run and restore your own session",
		handler: async (_args, ctx) => {
			if (!run || run.done) {
				ctx.ui.notify("work-review-stop: no active run.", "warning");
				return;
			}
			run.cancelled = true;
			const pending = run.pendingTurn;
			if (pending) {
				run.pendingTurn = undefined;
				pending.reject(new Error("work-review: interrupted"));
			}
			ctx.abort();
			run.gate.resume();
			ctx.ui.notify("work-review: stopping…", "warning");
		},
	});

	pi.registerCommand("work-review-peek", {
		description: "Peek at the coder's or reviewer's latest output without switching onto it (args: coder|reviewer)",
		handler: async (args, ctx) => {
			if (!ctx.hasUI) {
				ctx.ui.notify("work-review-peek requires a TUI.", "error");
				return;
			}
			if (!run) {
				ctx.ui.notify("work-review-peek: no /work-review run this session.", "warning");
				return;
			}
			const target: WorkReviewMode = args.trim().toLowerCase() === "reviewer" ? "reviewer" : "coder";
			const text = run.lastAssistantText[target] ?? "(nothing yet)";
			const file = target === "coder" ? run.coderFile : run.reviewerFile;
			await ctx.ui.custom<undefined>(
				(tui, theme, _keybindings, done) => {
					const scroll = new ScrollView([], { height: Math.max(6, (tui.terminal.rows ?? 24) - 6), scrollbar: "auto" });
					let lastWidth = 0;
					return {
						render(width: number): readonly string[] {
							if (width !== lastWidth) {
								lastWidth = width;
								scroll.setLines(wrapTextWithAnsi(text, Math.max(1, width)));
							}
							return [
								theme.fg("accent", `${target.toUpperCase()} — latest output`),
								theme.fg("muted", file),
								"",
								...scroll.render(width),
								theme.fg("muted", "↑/↓ scroll · Esc close · /resume this session for full native history"),
							];
						},
						handleInput(data: string): void {
							if (matchesKey(data, "escape") || data === "q") {
								done(undefined);
								return;
							}
							scroll.handleScrollKey(data);
							tui.requestRender();
						},
					};
				},
				{ overlay: true },
			);
		},
	});
}
