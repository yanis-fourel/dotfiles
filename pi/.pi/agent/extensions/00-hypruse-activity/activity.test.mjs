import { test } from "node:test";
import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { mkdtempSync, readFileSync, writeFileSync, existsSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { usesHypruse } from "./match.mjs";

test("MCP and direct CLI calls are detected", () => {
  assert.ok(usesHypruse("mcp__hypruse__desktop", {}));
  assert.ok(usesHypruse("bash", { command: "/usr/bin/hypruse pointer click 10 20" }));
  assert.ok(usesHypruse("bash", { command: "uvx hypruse screenshot" }));
  assert.ok(!usesHypruse("read", { path: "hypruse" }));
  assert.ok(!usesHypruse("bash", { command: "hypruse --help" }));
});

test("lifecycle, settle cleanup and kill-switch abort", async () => {
  const require = createRequire("/usr/lib/node_modules/@earendil-works/pi-coding-agent/package.json");
  const { createJiti } = require("jiti");
  const extension = (await createJiti(import.meta.url).import("./index.ts")).default;
  const dir = mkdtempSync(join(tmpdir(), "hypruse-test-"));
  const old = process.env.XDG_RUNTIME_DIR;
  process.env.XDG_RUNTIME_DIR = dir;
  const handlers = {};
  let aborted = false;
  const ctx = { sessionManager: { getSessionId: () => "test" }, abort: () => { aborted = true; } };
  const file = join(dir, "pi-hypruse", `${process.pid}.json`);
  try {
    extension({ on: (event, handler) => { handlers[event] = handler; } });
    handlers.before_agent_start();
    handlers.tool_execution_start({ toolName: "mcp__hypruse__desktop", args: {} }, ctx);
    const start = JSON.parse(readFileSync(file));
    handlers.tool_execution_start({ toolName: "bash", args: { command: "hypruse zoom 2 3" } }, ctx);
    assert.equal(JSON.parse(readFileSync(file)).started, start.started);
    handlers.agent_settled();
    assert.ok(!existsSync(file));
    handlers.before_agent_start();
    handlers.tool_execution_start({ toolName: "mcp__hypruse__desktop", args: {} }, ctx);
    const run = JSON.parse(readFileSync(file)).run;
    writeFileSync(join(dir, "pi-hypruse", "stop.json"), JSON.stringify({ runs: [run] }));
    await new Promise(resolve => setTimeout(resolve, 300));
    assert.ok(aborted);
    assert.ok(!existsSync(file));
    assert.equal(handlers.tool_call().block, true);
    handlers.before_agent_start();
    assert.equal(handlers.tool_call(), undefined);
  } finally {
    handlers.session_shutdown?.();
    if (old === undefined) delete process.env.XDG_RUNTIME_DIR;
    else process.env.XDG_RUNTIME_DIR = old;
    rmSync(dir, { recursive: true, force: true });
  }
});
