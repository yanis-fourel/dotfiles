/**
 * /work-review — isolated coder → reviewer loop.
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
 *    verdict text, fed back as the next prompt.
 *
 * The two sessions loop (coder implements → reviewer reviews → coder addresses
 * feedback → …) until the reviewer replies APPROVE or a round cap is hit. Both
 * sessions keep their own multi-turn history across rounds so later rounds have
 * continuity without cross-contaminating each other's context.
 */
import type { ThinkingLevel } from "@oh-my-pi/pi-agent-core";
import type { ExtensionAPI, ExtensionCommandContext } from "@oh-my-pi/pi-coding-agent";
import { AgentRegistry, createAgentSession, SessionManager, Settings } from "@oh-my-pi/pi-coding-agent";
import type { AssistantMessage, Model } from "@oh-my-pi/pi-ai";

// Tool split is the actual isolation/safety boundary for the reviewer: it can run
// tests/greps/reads but has no edit/write/ast_edit access.
const CODER_TOOLS = ["read", "edit", "write", "bash", "grep", "glob", "ast_grep", "todo"];
const REVIEWER_TOOLS = ["read", "grep", "glob", "bash", "ast_grep", "web_search"];

const THINKING_LEVELS: readonly ThinkingLevel[] = ["off", "minimal", "low", "medium", "high", "xhigh", "max"];
const ROUND_OPTIONS = ["3", "5", "8", "12"];
const DEFAULT_ROUNDS = "5";

interface RoundEntry {
	round: number;
	coderSummary: string;
	reviewVerdict: string;
	approved: boolean;
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
You do not see the reviewer's reasoning — only its verdict text, delivered as your next message when it requests changes.
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
Reply in EXACTLY this format, nothing before or after:
- First line: exactly "APPROVE" if the change is correct and complete, or exactly "REQUEST_CHANGES" otherwise.
- If REQUEST_CHANGES: a bullet list of concrete, actionable issues (file/line when applicable). Do not repeat points
  already resolved in a prior round.`;
}

async function runLoop(pi: ExtensionAPI, ctx: ExtensionCommandContext, choice: WorkReviewChoice): Promise<void> {
	const settings = Settings.isolated({
		"tools.approvalMode": "yolo",
		"compaction.enabled": true,
		"retry.enabled": true,
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
			disableExtensionDiscovery: true,
			appendSystemPrompt: buildReviewerPrompt(ctx.cwd),
		}),
	]);

	const rounds: RoundEntry[] = [];
	let approved = false;

	try {
		let coderPrompt = choice.task;

		for (let round = 1; round <= choice.maxRounds; round++) {
			ctx.ui.setWidget("work-review", [`work-review round ${round}/${choice.maxRounds}: coder working…`]);
			ctx.ui.setStatus("work-review", `round ${round}/${choice.maxRounds}: coding`);

			await coder.session.prompt(coderPrompt);
			const coderSummary = textOnly(coder.session.getLastAssistantMessage()) || "(coder returned no text summary)";

			ctx.ui.setWidget("work-review", [`work-review round ${round}/${choice.maxRounds}: reviewer checking…`]);
			ctx.ui.setStatus("work-review", `round ${round}/${choice.maxRounds}: reviewing`);

			const reviewPrompt =
				round === 1
					? `Original task:\n${choice.task}\n\nCoder's summary of its changes:\n${coderSummary}\n\nReview the actual repository state now.`
					: `Coder's summary of changes made to address your last feedback:\n${coderSummary}\n\nReview the actual repository state now.`;
			await reviewer.session.prompt(reviewPrompt);
			const reviewVerdict = textOnly(reviewer.session.getLastAssistantMessage()) || "(reviewer returned no text)";

			const roundApproved = /^APPROVE\b/i.test(reviewVerdict);
			rounds.push({ round, coderSummary, reviewVerdict, approved: roundApproved });

			if (roundApproved) {
				approved = true;
				ctx.ui.notify(`work-review: reviewer approved after round ${round}.`, "info");
				break;
			}

			if (round === choice.maxRounds) {
				ctx.ui.notify(`work-review: round cap (${choice.maxRounds}) reached without approval.`, "warning");
				break;
			}

			coderPrompt = `Reviewer feedback — address every point:\n${reviewVerdict}`;
		}
	} finally {
		ctx.ui.setWidget("work-review", undefined);
		ctx.ui.setStatus("work-review", undefined);
		await Promise.allSettled([coder.session.dispose(), reviewer.session.dispose()]);
	}

	const header = `## /work-review ${approved ? "— approved ✅" : "— round cap reached ⚠️"}
**Task:** ${choice.task}
**Coder:** ${modelLabel(choice.coderModel, choice.coderThinking)}
**Reviewer:** ${modelLabel(choice.reviewerModel, choice.reviewerThinking)}
**Rounds run:** ${rounds.length}/${choice.maxRounds}
${approved ? "" : "\nChanges from the last round remain in the working tree. Run `git diff` to inspect them; re-run /work-review to continue iterating."}`;

	const roundLog = rounds
		.map(
			r =>
				`### Round ${r.round}\n**Coder:**\n${r.coderSummary}\n\n**Reviewer:** ${r.approved ? "APPROVE" : "REQUEST_CHANGES"}\n${r.approved ? "" : r.reviewVerdict}`,
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

			try {
				await runLoop(pi, ctx, choice);
			} catch (err) {
				ctx.ui.notify(`work-review failed: ${err instanceof Error ? err.message : String(err)}`, "error");
			}
		},
	});
}
