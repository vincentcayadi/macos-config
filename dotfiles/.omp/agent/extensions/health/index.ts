import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent"
import { extensionHealthEntries, renderExtensionHealth, setExtensionHealth } from "../shared/health"

export default function extensionHealth(pi: ExtensionAPI) {
  setExtensionHealth("health", { state: "loaded" })

  pi.registerCommand("extension-status", {
    description: "Show extension load state, last result, and activity counters",
    handler: async (_args, ctx) => {
      ctx.ui.notify(renderExtensionHealth(), "info")
    },
  })

  pi.on("session_start", async (_event, ctx) => {
    const issues = extensionHealthEntries().filter(([, entry]) => entry.state !== "loaded")
    if (issues.length === 0) return
    ctx.ui.notify(`Extension issues:\n${renderExtensionHealth(issues)}`, "warning")
  })
}
