/**
 * Key Rotator Extension
 *
 * Automatically rotates through multiple NVIDIA API keys when making requests
 * to integrate.api.nvidia.com. Distributes rate limits across your free-tier
 * keys so you can keep coding without hitting caps.
 *
 * Setup:
 *   1. Edit ~/.pi/agent/extensions/key-rotator/keys.json with your 5 NVIDIA API keys
 *   2. Reload pi (or restart)
 *   3. Use /keys to check current status
 */

import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

// ─── Configuration ──────────────────────────────────────────────────────────
const CONFIG_PATH = join(
  process.env.HOME ?? process.env.USERPROFILE ?? ".",
  ".pi",
  "agent",
  "extensions",
  "key-rotator",
  "keys.json",
);

interface KeysConfig {
  keys: string[];
  currentIndex: number;
}

function loadKeys(): KeysConfig {
  if (!existsSync(CONFIG_PATH)) {
    const template: KeysConfig = {
      keys: [
        "nvapi-your-nvidia-key-1-here",
        "nvapi-your-nvidia-key-2-here",
        "nvapi-your-nvidia-key-3-here",
        "nvapi-your-nvidia-key-4-here",
        "nvapi-your-nvidia-key-5-here",
      ],
      currentIndex: 0,
    };
    writeFileSync(CONFIG_PATH, JSON.stringify(template, null, 2), "utf8");
    return template;
  }

  const raw = readFileSync(CONFIG_PATH, "utf8");
  return JSON.parse(raw) as KeysConfig;
}

function saveKeys(config: KeysConfig) {
  writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 2), "utf8");
}

// ─── State ──────────────────────────────────────────────────────────────────
let config = loadKeys();

function nextKey(): string {
  const key = config.keys[config.currentIndex];
  config.currentIndex = (config.currentIndex + 1) % config.keys.length;
  saveKeys(config);
  return key;
}

function maskKey(k: string): string {
  if (k.length <= 8) return "****";
  return k.slice(0, 4) + "..." + k.slice(-4);
}

// ─── Extension ──────────────────────────────────────────────────────────────
export default function (pi: ExtensionAPI) {
  // Add only the specific NVIDIA model mentioned in Reddit to the scoped model list
  pi.on("session_start", async (_event, ctx) => {
    const allModels = pi.getAllModels();
    const targetModel = allModels.find(
      (m) => m.id === "nvidia/nemotron-3-super" || m.id === "nvidia/nemotron-3-super-120b-a12b",
    );

    if (targetModel) {
      ctx.sessionManager.setScopedModels([{ model: targetModel }]);
    }
  });

  // Rotate NVIDIA key before auth resolution so stream options get the new key.
  // This is provider-level (model registry), not payload-level header rewriting.
  pi.on("context", (_event, ctx) => {
    if (ctx.model?.provider !== "nvidia") {
      return undefined;
    }

    const key = nextKey();
    pi.registerProvider("nvidia", { apiKey: key });
    return undefined;
  });

  // /keys command to check status
  pi.registerCommand("keys", {
    description: "Show current key rotation status",
    handler: async (_args, ctx) => {
      config = loadKeys();
      const count = config.keys.length;
      const lastIdx = (config.currentIndex - 1 + count) % count;
      const lastKey = config.keys[lastIdx];
      const nextKeyStr = config.keys[config.currentIndex];

      const lines = [
        `Key Rotation (${count} keys)`,
        `─────────────────────────────`,
        `Next key: ${maskKey(nextKeyStr)}`,
        `Last used: ${maskKey(lastKey)}`,
        ``,
        ...config.keys.map((k, i) => {
          const marker = i === config.currentIndex ? " ← next" : i === lastIdx ? " ← last" : "";
          return `  ${i + 1}. ${maskKey(k)}${marker}`;
        }),
      ];

      ctx.ui.notify(lines.join("\n"), "info");
    },
  });
}
