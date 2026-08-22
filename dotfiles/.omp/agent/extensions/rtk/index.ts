// RTK Pi extension — rewrites bash commands to use rtk for token savings.
// Requires: rtk >= 0.23.0 in PATH.
//
// This is a thin delegating extension: all rewrite logic lives in `rtk rewrite`,
// which is the single source of truth (src/discover/registry.rs).
// To add or change rewrite rules, edit the Rust registry — not this file.
//
// Exit code contract for `rtk rewrite`:
//   0 + stdout  Rewrite found → mutate command
//   1           No RTK equivalent → pass through unchanged
//   3 + stdout  Rewrite (advisory) → mutate command

import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent"
import { isToolCallEventType } from "@oh-my-pi/pi-coding-agent"
import { incrementExtensionCounter, setExtensionHealth } from "../shared/health"

const REWRITE_TIMEOUT_MS = 2_000
const MIN_SUPPORTED_RTK_MINOR = 23

// Parse "X.Y.Z" semver, return [major, minor, patch] or null.
export function parseSemver(raw: string): [number, number, number] | null {
  const m = raw.trim().match(/(\d+)\.(\d+)\.(\d+)/)
  if (!m) return null
  return [parseInt(m[1], 10), parseInt(m[2], 10), parseInt(m[3], 10)]
}

// Calls `rtk rewrite`; returns the rewritten command or null (pass through).
async function rewriteCommand(
  pi: ExtensionAPI,
  cmd: string,
  signal?: AbortSignal
): Promise<string | null> {
  const result = await pi.exec("rtk", ["rewrite", cmd], {
    timeout: REWRITE_TIMEOUT_MS,
    signal,
  })
  if (result.killed) return null
  if (result.code !== 0 && result.code !== 3) return null
  return result.stdout.trim() || null
}

export default async function rtkExtension(pi: ExtensionAPI) {
  const ver = await pi.exec("rtk", ["--version"], { timeout: REWRITE_TIMEOUT_MS })
  if (ver.code !== 0) {
    console.warn("[rtk] rtk binary not found in PATH — extension disabled")
    setExtensionHealth("rtk", { state: "disabled", detail: "binary not found" })
    return
  }

  const version = ver.stdout.trim()
  const parsed = parseSemver(version.replace(/^rtk\s+/, ""))
  if (!parsed) {
    console.warn(`[rtk] cannot parse version ${JSON.stringify(version)} — extension disabled`)
    setExtensionHealth("rtk", { state: "disabled", detail: "unparseable version" })
    return
  }

  const [major, minor] = parsed
  if (major === 0 && minor < MIN_SUPPORTED_RTK_MINOR) {
    console.warn(`[rtk] ${version} is too old (need >= 0.23.0) — extension disabled`)
    setExtensionHealth("rtk", { state: "disabled", detail: `${version} too old` })
    return
  }

  setExtensionHealth("rtk", { state: "loaded", detail: version })
  pi.on("tool_call", async (event, ctx) => {
    try {
      if (!isToolCallEventType("bash", event)) return

      const cmd = event.input.command
      if (typeof cmd !== "string" || cmd.trim() === "") return
      incrementExtensionCounter("rtk", "calls")

      const normalized = cmd.trimStart()
      if (normalized === "rtk" || normalized.startsWith("rtk ")) {
        incrementExtensionCounter("rtk", "bypassed")
        return
      }
      if (process.env.RTK_DISABLED === "1") {
        incrementExtensionCounter("rtk", "disabled")
        return
      }

      const rewritten = await rewriteCommand(pi, cmd, ctx.signal)
      if (rewritten && rewritten !== cmd) {
        event.input.command = rewritten
        incrementExtensionCounter("rtk", "rewrites")
      } else {
        incrementExtensionCounter("rtk", "passthrough")
      }
    } catch (err) {
      incrementExtensionCounter("rtk", "errors")
      setExtensionHealth("rtk", { state: "degraded", detail: "last rewrite failed open" })
      console.warn("[rtk] unexpected error in tool_call handler; passing through command", err)
    }
  })
}
