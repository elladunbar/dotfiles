/**
 * Filter built-in remote providers from the model picker.
 * Keeps only local/offline providers: llama.cpp, ollama.
 *
 * This is a monkeypatch on Pi's internal ModelRuntime.builtins map.
 * It may break on future Pi updates if internal structure changes.
 * To disable: rename or delete this file, then restart Pi.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Providers to REMOVE (remote/cloud)
const REMOTE_PROVIDERS = [
  "openai",
  "openai-codex",
  "anthropic",
  "google",
  "google-vertex",
  "deepseek",
  "nvidia",
  "xai",
  "groq",
  "mistral",
  "cerebras",
  "openrouter",
  "azure-openai-responses",
  "amazon-bedrock",
  "cloudflare-ai-gateway",
  "cloudflare-workers-ai",
  "opencode",
  "opencode-go",
  "together",
  "qwen-token-plan",
  "qwen-token-plan-individual",
  "qwen-token-plan-cn",
  "xiaomi",
  "xiaomi-token-plan-ams",
  "xiaomi-token-plan-cn",
  "xiaomi-token-plan-sgp",
  "zai",
  "zai-coding-cn",
  "fireworks",
  "baseten",
  "kimi-coding",
  "minimax",
  "minimax-cn",
  "ant-ling",
  "radius",
  "huggingface",
  "vercel-ai-gateway",
  "github-copilot",
  "moonshotai",
  "moonshotai-cn",
];

function filterModels(models: any[]) {
  return models.filter((m: any) => !REMOTE_PROVIDERS.includes(m.provider));
}

export default async function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    const registry = ctx.modelRegistry as any;
    const runtime = registry?.runtime as any;

    if (!runtime) return;

    // Patch registry.getAvailable
    if (registry.getAvailable) {
      const orig = registry.getAvailable.bind(registry);
      registry.getAvailable = () => filterModels(orig());
    }

    // Patch ModelRuntime.getAvailableSnapshot (the main one the picker uses)
    if (runtime.getAvailableSnapshot) {
      const orig = runtime.getAvailableSnapshot.bind(runtime);
      runtime.getAvailableSnapshot = () => filterModels(orig());
    }

    // Patch runtime.models.getModels if it exists
    const modelsStore = runtime?.models;
    if (modelsStore?.getModels) {
      const orig = modelsStore.getModels.bind(modelsStore);
      modelsStore.getModels = () => filterModels(orig());
    }

    // Block network refreshes
    if (runtime.refresh) {
      const origRefresh = runtime.refresh.bind(runtime);
      runtime.refresh = async (options: any) => {
        if (options?.allowNetwork) {
          return { aborted: true, errors: new Map(), modelsUpdated: 0 };
        }
        return origRefresh(options);
      };
    }

    // Delete from builtins
    const builtins = runtime?.builtins as Map<string, any>;
    if (builtins instanceof Map) {
      for (const pid of REMOTE_PROVIDERS) builtins.delete(pid);
    }

    // Delete from models store
    if (modelsStore?.deleteProvider) {
      for (const pid of REMOTE_PROVIDERS) modelsStore.deleteProvider(pid);
    }

    // Rebuild snapshot
    if (runtime.updateModelSnapshot) {
      runtime.updateModelSnapshot();
    }
  });
}
