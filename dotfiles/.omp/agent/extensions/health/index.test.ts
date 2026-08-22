import { beforeEach, describe, expect, test } from "bun:test"
import { extensionHealthEntries, setExtensionHealth } from "../shared/health"
import extensionHealth from "./index"

type Handler = (...args: unknown[]) => Promise<void>

function fixture() {
  let sessionStart: Handler | undefined
  let status: Handler | undefined
  const notifications: Array<{ message: string; level: string }> = []
  const pi = {
    registerCommand(_name: string, definition: { handler: Handler }) {
      status = definition.handler
    },
    on(name: string, handler: Handler) {
      if (name === "session_start") sessionStart = handler
    },
  }
  extensionHealth(pi as never)
  if (!sessionStart || !status) throw new Error("health handlers were not registered")
  const ctx = {
    ui: {
      notify(message: string, level: string) {
        notifications.push({ message, level })
      },
    },
  }
  return { sessionStart, status, notifications, ctx }
}

beforeEach(() => {
  for (const [name] of extensionHealthEntries()) setExtensionHealth(name, { state: "loaded", detail: undefined })
})

describe("extension health", () => {
  test("stays silent when every extension is healthy", async () => {
    const { sessionStart, notifications, ctx } = fixture()
    await sessionStart({}, ctx)
    expect(notifications).toEqual([])
  })

  test("reports only unhealthy extensions at session start", async () => {
    const { sessionStart, notifications, ctx } = fixture()
    setExtensionHealth("rtk", { state: "degraded", detail: "rewrite failed" })
    setExtensionHealth("check", { state: "loaded", detail: "passed" })

    await sessionStart({}, ctx)

    expect(notifications).toHaveLength(1)
    expect(notifications[0].level).toBe("warning")
    expect(notifications[0].message).toContain("rtk | degraded | rewrite failed")
    expect(notifications[0].message).not.toContain("check | loaded")
  })

  test("keeps complete status available on demand", async () => {
    const { status, notifications, ctx } = fixture()
    setExtensionHealth("rtk", { state: "disabled", detail: "binary missing" })
    setExtensionHealth("check", { state: "loaded", detail: "passed" })

    await status("", ctx)

    expect(notifications).toHaveLength(1)
    expect(notifications[0].level).toBe("info")
    expect(notifications[0].message).toContain("rtk | disabled | binary missing")
    expect(notifications[0].message).toContain("check | loaded | passed")
  })
})
