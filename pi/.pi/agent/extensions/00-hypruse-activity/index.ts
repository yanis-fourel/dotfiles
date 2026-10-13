import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { mkdirSync, readFileSync, writeFileSync, renameSync, unlinkSync } from "node:fs";
import { join } from "node:path";
import { randomUUID } from "node:crypto";
import { usesHypruse } from "./match.mjs";

// Automatic runtime telemetry; no model-callable start/stop tool.
export default function (pi: ExtensionAPI) {
  const dir = join(process.env.XDG_RUNTIME_DIR || `/run/user/${process.getuid!()}`, "pi-hypruse");
  const file = join(dir, `${process.pid}.json`);
  let timer: ReturnType<typeof setInterval> | undefined;
  let active: any;
  let context: ExtensionContext | undefined;
  let stopped = false;
  let lastWrite = 0;
  function clear() {
    active = undefined;
    if (timer) clearInterval(timer);
    timer = undefined;
    try { unlinkSync(file); } catch {}
  }
  function publish() {
    if (!active) return;
    active.heartbeat = Date.now();
    writeFileSync(file + ".tmp", JSON.stringify(active), { mode: 0o600 });
    renameSync(file + ".tmp", file);
    lastWrite = Date.now();
  }
  function tick() {
    if (!active) return;
    try {
      const stop = JSON.parse(readFileSync(join(dir, "stop.json"), "utf8"));
      if (stop.runs?.includes(active.run)) {
        stopped = true;
        context?.abort();
        clear();
        return;
      }
    } catch {}
    if (Date.now() - lastWrite >= 1000) {
      try { publish(); } catch { /* Reader detects missing/stale heartbeat. */ }
    }
  }
  pi.on("before_agent_start", () => { clear(); stopped = false; });
  pi.on("tool_call", () => {
    if (stopped) return { block: true, reason: "Desktop run interrupted by the user's kill switch." };
  });
  pi.on("tool_execution_start", (event, ctx) => {
    if (stopped || !usesHypruse(event.toolName, event.args)) return;
    context = ctx;
    if (active) return;
    mkdirSync(dir, { recursive: true, mode: 0o700 });
    const stat = readFileSync(`/proc/${process.pid}/stat`, "utf8");
    active = {
      pid: process.pid,
      processStart: stat.slice(stat.lastIndexOf(")") + 2).split(" ")[19],
      session: ctx.sessionManager.getSessionId(),
      run: randomUUID(), started: Date.now(), heartbeat: Date.now(),
    };
    publish();
    timer = setInterval(tick, 200);
    timer.unref();
  });
  // before_settle avoids waiting for other extensions' slow notification handlers.
  pi.on("agent_before_settle", () => { tick(); });
  pi.on("agent_settled", clear);
  pi.on("session_shutdown", clear);
}
