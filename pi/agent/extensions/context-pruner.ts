import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

// ─── Configuration ──────────────────────────────────────────────────────────
const MAX_READ_CHARS  = 16000;   // ~4k tokens (4 chars/token heuristic)
const MAX_BASH_CHARS  =  8000;   // ~2k tokens
const CTX_SIZE        = 65536;
const CONTEXT_WARN_PCT  = 0.70;  // warn at 70% of context window
const CONTEXT_WARN_THRESHOLD = Math.floor(CTX_SIZE * CONTEXT_WARN_PCT); // 45875

let warnedContextThreshold = false;

export default function (pi: ExtensionAPI) {
  // Reset warning flag on new session / restart
  pi.on("session_start", async () => { warnedContextThreshold = false; });
  // Reset on compaction so we warn again if context grows past threshold
  pi.on("session_compact", async () => { warnedContextThreshold = false; });

  // ── Truncate oversized tool results ──────────────────────────────────────
  pi.on("tool_result", async (event, ctx) => {
    // File reads: cap at ~4k tokens so a single read can't blow the context
    if (event.toolName === "read") {
      const text = event.content[0]?.type === "text" ? event.content[0].text : "";
      if (text.length > MAX_READ_CHARS) {
        const kept    = text.slice(0, MAX_READ_CHARS);
        const totalLines = text.split("\n").length;
        const keptLines   = kept.split("\n").length;
        const cutLines    = totalLines - keptLines;
        const limit       = Math.ceil(MAX_READ_CHARS / 4);

        return {
          content: [{
            type: "text",
            text: `${kept}\n\n⚠️ TRUNCATED: ${cutLines} of ${totalLines} lines omitted (output exceeds ${limit} token limit).\nUse grep, sed, or line-range reads (e.g., offset/limit) for targeted content.`,
          }],
          details: { truncated: true, linesKept: keptLines, linesTotal: totalLines },
        };
      }
    }

    // Bash output: cap at ~2k tokens — find / test runs / etc. can be huge
    if (event.toolName === "bash") {
      const text = event.content[0]?.type === "text" ? event.content[0].text : "";
      if (text.length > MAX_BASH_CHARS) {
        const kept    = text.slice(0, MAX_BASH_CHARS);
        const totalLines = text.split("\n").length;
        const keptLines   = kept.split("\n").length;
        const cutLines    = totalLines - keptLines;
        const limit       = Math.ceil(MAX_BASH_CHARS / 4);

        return {
          content: [{
            type: "text",
            text: `${kept}\n\n⚠️ TRUNCATED: ${cutLines} of ${totalLines} lines omitted (output exceeds ${limit} token limit).\nConsider grep, sed, or targeted filters instead of running broad commands.`,
          }],
          details: { truncated: true },
        };
      }
    }
  });

  // ── Context usage warning ────────────────────────────────────────────────
  // Fires once per turn, before the provider request.
  // Warns once per session (or since last compaction) so we don't spam.
  pi.on("context", async (_event, ctx) => {
    const usage = ctx.getContextUsage();
    if (!usage) return;

    if (usage.tokens > CONTEXT_WARN_THRESHOLD && !warnedContextThreshold) {
      const pct = Math.round((usage.tokens / CTX_SIZE) * 100);
      ctx.ui.notify(
        `Context at ${pct}% (${usage.tokens.toLocaleString()} / ${CTX_SIZE} tokens) — consider compacting`,
        "warning",
      );
      warnedContextThreshold = true;
    }
  });
}
