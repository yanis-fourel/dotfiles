/**
 * inspect.ts — see exactly what pi sends to and receives from the LLM.
 *
 * Logs, in order, for every turn:
 *   - before_agent_start : your prompt + the system prompt in effect
 *   - before_provider_request : the FULL serialized request (messages,
 *     tools, temperature, model, etc.) exactly as sent over the wire
 *   - after_provider_response : HTTP status/headers of the reply
 *   - message_end : the finalized message (assistant text / tool calls /
 *     tool results / usage) as pi records it
 *
 * Everything is appended to a per-session log file. Tail it in another
 * terminal while you chat:
 *
 *   tail -f .pi/inspect/<session>.log
 *
 * Commands:
 *   /inspect        - show the log file path + a tail command, as a notify
 *   /inspect-last    - open the most recent provider request payload in the
 *                      built-in editor view (read-only-ish; press Esc/Ctrl+C
 *                      to close without sending anything)
 */
import { appendFileSync, mkdirSync } from "node:fs";
import { join } from "node:path";
import { CONFIG_DIR_NAME, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

function ts(): string {
  return new Date().toISOString();
}

export default function (pi: ExtensionAPI) {
  let logFile: string | undefined;
  let lastRequestPayload: unknown;
  let lastResponseInfo: unknown;

  function log(section: string, data: unknown) {
    if (!logFile) return;
    const body = typeof data === "string" ? data : JSON.stringify(data, null, 2);
    appendFileSync(
      logFile,
      `\n===== [${ts()}] ${section} =====\n${body}\n`,
      "utf8",
    );
  }

  pi.on("session_start", (_event, ctx) => {
    const dir = join(ctx.cwd, CONFIG_DIR_NAME, "inspect");
    mkdirSync(dir, { recursive: true });
    const stamp = new Date().toISOString().replace(/[:.]/g, "-");
    logFile = join(dir, `${stamp}.log`);
    appendFileSync(logFile, `Inspect log for session starting ${ts()}\n`, "utf8");

    ctx.ui.setStatus("inspect", `inspect: ${logFile}`);
    ctx.ui.notify(`Prompt inspector logging to: ${logFile}`, "info");
  });

  pi.on("session_shutdown", (_event, ctx) => {
    ctx.ui.setStatus("inspect", undefined);
  });

  // What you typed + the system prompt that will be used for this turn.
  pi.on("before_agent_start", (event, ctx) => {
    log("before_agent_start (your prompt + system prompt)", {
      prompt: event.prompt,
      images: event.images?.length ?? 0,
      systemPrompt: event.systemPrompt,
      selectedTools: event.systemPromptOptions?.selectedTools,
      toolSnippets: event.systemPromptOptions?.toolSnippets,
      promptGuidelines: event.systemPromptOptions?.promptGuidelines,
      skills: event.systemPromptOptions?.skills,
      contextFiles: event.systemPromptOptions?.contextFiles?.map(
        (f: { path?: string }) => f.path,
      ),
    });
  });

  // The exact payload sent to the provider: messages, tools, temperature, model...
  pi.on("before_provider_request", (event, _ctx) => {
    lastRequestPayload = event.payload;
    log("before_provider_request (raw payload sent to the API)", event.payload);
    // Don't modify anything; just observe. Return undefined to keep as-is.
  });

  pi.on("after_provider_response", (event, _ctx) => {
    lastResponseInfo = { status: event.status, headers: event.headers };
    log("after_provider_response (HTTP status + headers)", lastResponseInfo);
  });

  // The finalized message pi recorded: assistant text/tool-calls, or a tool result.
  pi.on("message_end", (event, _ctx) => {
    log(`message_end (role=${event.message.role})`, event.message);
  });

  pi.registerCommand("inspect", {
    description: "Show the path to the prompt-inspector log file",
    handler: async (_args, ctx) => {
      if (!logFile) {
        ctx.ui.notify("Inspector not initialized yet.", "warning");
        return;
      }
      ctx.ui.notify(
        `Log file: ${logFile}\nTail it with: tail -f ${logFile}`,
        "info",
      );
    },
  });

  pi.registerCommand("inspect-last", {
    description: "View the most recent raw provider request payload",
    handler: async (_args, ctx) => {
      if (lastRequestPayload === undefined) {
        ctx.ui.notify("No provider request captured yet. Send a message first.", "warning");
        return;
      }
      const text = JSON.stringify(lastRequestPayload, null, 2);
      // Read-only viewing via the built-in multi-line editor dialog.
      // Escape/Ctrl+C closes it without doing anything else.
      await ctx.ui.editor("Last provider request payload (Esc to close):", text);
    },
  });
}
