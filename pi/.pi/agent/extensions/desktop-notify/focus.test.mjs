import { test } from "node:test";
import assert from "node:assert/strict";
import { piFocused } from "./focus.mjs";

const terminal = { pid: 10, address: "terminal" };
const browser = { pid: 20, address: "browser" };
function fixture({ active = terminal, clients = "30\t%43", windows = [terminal, browser], tmux = true, fail = false } = {}) {
  return {
    env: { HYPRLAND_INSTANCE_SIGNATURE: "test", ...(tmux ? { TMUX: "test", TMUX_PANE: "%43" } : {}) },
    pid: 30,
    parents: async () => new Set([30, 10]),
    command: async (name, args) => {
      if (fail) throw new Error("Unavailable");
      if (name === "tmux") return clients;
      return JSON.stringify(args[1] === "clients" ? windows : active);
    },
  };
}
test("focused terminal and Pi pane", async () => assert.equal(await piFocused(fixture()), true));
test("another application focused", async () => assert.equal(await piFocused(fixture({ active: browser })), false));
test("another tmux pane selected", async () => assert.equal(await piFocused(fixture({ clients: "30\t%44" })), false));
test("detached tmux", async () => assert.equal(await piFocused(fixture({ clients: "" })), false));
test("direct terminal without tmux", async () => assert.equal(await piFocused(fixture({ tmux: false })), true));
test("unavailable compositor is unknown", async () => assert.equal(await piFocused(fixture({ fail: true })), null));
test("shared terminal PID is ambiguous", async () => assert.equal(await piFocused(fixture({ windows: [terminal, { pid: 10, address: "other" }] })), null));
test("another attached client displays Pi", async () => assert.equal(await piFocused(fixture({ clients: "99\t%44\n30\t%43" })), true));
