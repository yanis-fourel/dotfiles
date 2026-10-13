import { readFile } from "node:fs/promises";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const exec = promisify(execFile);
export async function run(command, args) {
  const { stdout } = await exec(command, args, { timeout: 2500, maxBuffer: 1024 * 1024 });
  return stdout;
}

export async function ancestors(pid) {
  const result = new Set();
  while (pid > 1 && !result.has(pid)) {
    result.add(pid);
    const stat = await readFile(`/proc/${pid}/stat`, "utf8");
    // comm can contain spaces and parentheses.
    pid = Number(stat.slice(stat.lastIndexOf(")") + 2).split(" ")[1]);
  }
  return result;
}

// null means focus could not be established. Never guess based on window title.
export async function piFocused({ env = process.env, pid = process.pid, command = run, parents = ancestors } = {}) {
  try {
    if (!env.HYPRLAND_INSTANCE_SIGNATURE) return null;
    const windows = JSON.parse(await command("hyprctl", ["-j", "clients"]));
    const active = JSON.parse(await command("hyprctl", ["-j", "activewindow"]));
    const roots = [];
    if (env.TMUX && env.TMUX_PANE) {
      // Use the actual attached clients, not the tmux server's ancestry.
      const clients = await command("tmux", ["list-clients", "-F", "#{client_pid}\t#{pane_id}"]);
      for (const line of clients.trim().split("\n")) {
        const [clientPid, pane] = line.split("\t");
        if (pane === env.TMUX_PANE) roots.push(Number(clientPid));
      }
      if (!roots.length) return false; // Detached or another window/pane selected.
    } else {
      roots.push(pid);
    }
    let ambiguous = false;
    for (const root of roots) {
      const lineage = await parents(root);
      const matches = windows.filter(w => lineage.has(w.pid));
      if (!matches.length) { ambiguous = true; continue; }
      if (matches.some(w => w.address === active.address)) {
        // Some terminal emulators share one PID across multiple windows.
        if (matches.length === 1) return true;
        ambiguous = true;
      }
    }
    return ambiguous ? null : false;
  } catch {
    return null;
  }
}
