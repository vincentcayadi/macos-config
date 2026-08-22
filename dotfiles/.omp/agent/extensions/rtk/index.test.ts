import { describe, expect, mock, test } from "bun:test"

mock.module("@oh-my-pi/pi-coding-agent", () => ({
  isToolCallEventType: (name: string, event: { toolName?: string }) => event.toolName === name,
}))

// Dynamic import is required so Bun installs the host-package mock before extension evaluation.
const { default: rtkExtension, parseSemver } = await import("./index")

type ToolEvent = { toolName: "bash"; input: { command: string } }
type ToolHandler = (event: ToolEvent, ctx: { signal?: AbortSignal }) => Promise<void>

function fakePi(version: string, rewritten = "") {
  let handler: ToolHandler | undefined
  const exec = mock(async (_command: string, args: string[]) => {
    if (args[0] === "--version") return { code: 0, stdout: version, stderr: "", killed: false }
    return { code: rewritten ? 3 : 1, stdout: rewritten, stderr: "", killed: false }
  })
  return {
    pi: {
      exec,
      on(name: string, callback: ToolHandler) {
        if (name === "tool_call") handler = callback
      },
    },
    exec,
    handler: () => handler,
  }
}

describe("rtk extension", () => {
  test("parses semantic versions", () => {
    expect(parseSemver("rtk 0.45.0")).toEqual([0, 45, 0])
    expect(parseSemver("unknown")).toBeNull()
  })

  test("disables itself when version output is unparseable", async () => {
    const fixture = fakePi("development build")
    await rtkExtension(fixture.pi as never)
    expect(fixture.handler()).toBeUndefined()
  })

  test("bypasses whitespace-prefixed rtk commands", async () => {
    const fixture = fakePi("rtk 0.45.0")
    await rtkExtension(fixture.pi as never)
    const handler = fixture.handler()
    if (!handler) throw new Error("RTK handler was not registered")
    const event: ToolEvent = { toolName: "bash", input: { command: "   rtk git status" } }
    await handler(event, {})
    expect(event.input.command).toBe("   rtk git status")
    expect(fixture.exec).toHaveBeenCalledTimes(1)
  })

  test("rewrites supported Bash commands", async () => {
    const fixture = fakePi("rtk 0.45.0", "rtk ps aux")
    await rtkExtension(fixture.pi as never)
    const handler = fixture.handler()
    if (!handler) throw new Error("RTK handler was not registered")
    const event: ToolEvent = { toolName: "bash", input: { command: "ps aux" } }
    await handler(event, {})
    expect(event.input.command).toBe("rtk ps aux")
    expect(fixture.exec).toHaveBeenCalledTimes(2)
  })
})
