import { describe, expect, mock, test } from "bun:test"

mock.module("@oh-my-pi/pi-coding-agent", () => ({
  isToolCallEventType: (name: string, event: { toolName?: string }) => event.toolName === name,
}))

// Dynamic import is required so Bun installs the host-package mock before extension evaluation.
const { applyTaskProtocol } = await import("./index")

describe("worker output policy", () => {
  test("puts compact Chinese policy inside shared constraints", () => {
    const input = {
      context: "# Goal\nReview the code\n\n# Constraints\n- Preserve behavior\n\n# Contract\n- Return findings",
      tasks: [{ agent: "reviewer", task: "Review exported APIs" }],
    }
    const applied = applyTaskProtocol(input)
    expect(input.context).toStartWith("# Goal")
    expect(input.context).toContain("# Constraints\n[worker-policy]\n自然语言仅简体中文")
    expect(input.context).toContain("技术字符串原样")
    expect(input.tasks[0].task).toBe("Review exported APIs")
    expect(applied).toEqual({ contexts: 1, tasks: 0 })
  })

  test("falls back to individual tasks when shared context is unstructured", () => {
    const input = {
      context: "共享上下文",
      tasks: [
        { agent: "sonic", task: "收集版本" },
        { agent: "reviewer", task: "审查行为" },
      ],
    }
    expect(applyTaskProtocol(input)).toEqual({ contexts: 0, tasks: 2 })
    expect(input.context).toBe("共享上下文")
    expect(input.tasks[0].task).toStartWith("[worker-policy]")
    expect(input.tasks[1].task).toStartWith("[worker-policy]")
  })

  test("is idempotent", () => {
    const input = {
      context: "# Goal\n收集版本\n\n# Constraints\n- 保持准确\n\n# Contract\n- 返回版本",
      tasks: [{ agent: "sonic", task: "收集版本" }],
    }
    applyTaskProtocol(input)
    expect(applyTaskProtocol(input)).toEqual({ contexts: 0, tasks: 0 })
    expect(input.context.match(/\[worker-policy\]/g)).toHaveLength(1)
    expect(input.tasks[0].task).toBe("收集版本")
  })

  test("keeps the compact policy in legacy flat mode", () => {
    const input = { agent: "reviewer", task: "Review the code" }
    expect(applyTaskProtocol(input)).toEqual({ contexts: 0, tasks: 1 })
    expect(input.task).toStartWith("[worker-policy]")
    expect(input.task).toContain("自然语言仅简体中文")
    expect(input.task).toContain("不添加未观察事实")
  })
})
