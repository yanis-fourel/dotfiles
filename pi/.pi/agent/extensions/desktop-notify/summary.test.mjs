import { test } from "node:test";
import assert from "node:assert/strict";
import { summarize, escapeMarkup, oneLine } from "./summary.mjs";
const message = { content: [{ type: "text", text: "Draft prepared. Send it?" }], stopReason: "stop" };
test("model classification and one-line summary", async () => {
  const result = await summarize({ message, complete: async () => '{"status":"needs_input","summary":"Confirm whether to send the draft."}' });
  assert.deepEqual(result, { status: "needs_input", summary: "Confirm whether to send the draft." });
});
test("runtime abort overrides apparent success", async () => {
  assert.equal((await summarize({ aborted: true, message })).status, "interrupted");
});
test("runtime error overrides classification", async () => {
  const result = await summarize({ message: { ...message, stopReason: "error", errorMessage: "Rate limit exceeded" } });
  assert.deepEqual(result, { status: "failed", summary: "Rate limit exceeded" });
});
test("invalid summary never implies success", async () => {
  assert.equal((await summarize({ message, complete: async () => '{"status":"success"}' })).status, "unknown");
});
test("timeout aborts request and falls back to excerpt", async () => {
  let signal;
  const result = await summarize({ message, timeoutMs: 5, complete: async (_s, _u, s) => { signal = s; return new Promise(() => {}); } });
  assert.equal(result.status, "unknown");
  assert.equal(result.summary, "Draft prepared. Send it?");
  assert.equal(signal.aborted, true);
});
test("request failure falls back", async () => {
  assert.equal((await summarize({ message, complete: async () => { throw new Error(); } })).status, "unknown");
});
test("missing final result is not completion", async () => {
  assert.equal((await summarize({})).status, "unknown");
});
test("summary plain text is bounded and escaped", () => {
  assert.equal(oneLine("**Hello**\nworld"), "Hello world");
  assert.equal(oneLine("a".repeat(500)).length, 180);
  assert.equal(escapeMarkup("<b>&"), "&lt;b&gt;&amp;");
});
