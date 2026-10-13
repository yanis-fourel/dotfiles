// MCP names are exact runtime events, including calls nested through codemode.
// CLI detection covers direct shell commands (including absolute paths/uvx).
// Shell aliases, generated commands, and indirect scripts are not introspected.
export function usesHypruse(name, args) {
  if (/^mcp__hypruse__/.test(name)) return true;
  if (!/(^|[._])bash$/.test(name)) return false;
  return /(?:^|[\s;|&(/])hypruse\s+(?:desktop|screenshot|zoom|ui|marks|binds|wait[_-]for|pointer|keyboard|click[_-]ui|hypr|launch|use[_-]bind|sequence|clipboard)(?=\s|[;|&)]|$)/m.test(args?.command || "");
}
