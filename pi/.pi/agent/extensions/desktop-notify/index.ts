import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { piFocused, run } from "./focus.mjs";
import { summarize, labels, messageText, escapeMarkup, oneLine } from "./summary.mjs";

export default function (pi: ExtensionAPI) {
  let latest: any;
  let prompt = "";
  let generation = 0;
  let pending: AbortController | undefined;
  const reset = () => {
    generation++;
    pending?.abort();
    latest = undefined;
    prompt = "";
  };
  pi.on("session_start", reset);
  pi.on("session_shutdown", reset);
  pi.on("before_agent_start", event => {
    reset();
    if (event.messageType === "user") prompt = event.prompt;
  });
  pi.on("message_end", event => {
    if (event.message.role === "assistant") latest = event.message;
  });

  pi.on("agent_settled", async (event, ctx) => {
    if (ctx.mode !== "tui") return;
    const current = generation;
    const message = latest;
    const request = prompt;
    if (await piFocused() !== false || current !== generation) return;
    pending = new AbortController();
    const controller = pending;
    const model = ctx.model;
    const result = await summarize({
      aborted: event.aborted, message, prompt: request, signal: controller.signal,
      complete: model ? async (systemPrompt: string, content: string, signal: AbortSignal) => {
        // Separate, tool-free call: no agent continuation or notification recursion.
        const response = await ctx.modelRegistry.streamSimple(model, {
          systemPrompt,
          messages: [{ role: "user", content, timestamp: Date.now() }],
        }, { signal, maxTokens: 600, reasoning: "minimal" }).result();
        if (response.stopReason === "error" || response.stopReason === "aborted") throw new Error("Summary unavailable");
        return messageText(response);
      } : undefined,
    });
    if (pending === controller) pending = undefined;
    // User may have returned to Pi or started another run while summarizing.
    if (controller.signal.aborted || current !== generation || await piFocused() !== false) return;
    try {
      await run("notify-send", [
        "--app-name=Pi", "--urgency=normal",
        "--expire-time=0",
        `Pi — ${labels[result.status]}`, escapeMarkup(result.summary),
      ]);
    } catch (error) {
      ctx.ui.notify(`Desktop notification failed: ${String(error)}`, "warning");
    }
  });

  // Blocking extension dialogs can occur before agent_settled ever fires.
  pi.on("ui_prompt_start", async (event, ctx) => {
    if (ctx.mode !== "tui" || await piFocused() !== false) return;
    try {
      await run("notify-send", ["--app-name=Pi", "--urgency=normal", "--expire-time=0",
        "Pi — Needs your input", escapeMarkup(oneLine(event.title || "A confirmation or input dialog is waiting in Pi."))]);
    } catch { /* Do not disrupt the prompt. */ }
  });
}
