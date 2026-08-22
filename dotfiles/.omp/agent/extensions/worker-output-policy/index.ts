import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent"
import { isToolCallEventType } from "@oh-my-pi/pi-coding-agent"
import { incrementExtensionCounter, setExtensionHealth } from "../shared/health"

type TaskItem = Record<string, unknown> & {
  agent?: unknown
  task?: unknown
}

type TaskInput = Record<string, unknown> & {
  agent?: unknown
  context?: unknown
  task?: unknown
  tasks?: unknown
}

const BASE_MARKER = "[worker-policy]"
const BASE_RULES = `${BASE_MARKER}
自然语言仅简体中文 技术字符串原样 只答任务要求 删除客套 过程 复述 长日志 不添加未观察事实`

function prefixOnce(value: string, marker: string, prefix: string): string {
  if (value.includes(marker)) return value
  const body = value.trimStart()
  return body ? `${prefix}\n\n${body}` : prefix
}

function applyItemProtocol(item: TaskItem): number {
  if (typeof item.task !== "string") return 0
  const before = item.task
  item.task = prefixOnce(item.task, BASE_MARKER, BASE_RULES)
  return item.task === before ? 0 : 1
}

function injectSharedConstraint(context: string): string {
  if (context.includes(BASE_MARKER)) return context
  const heading = /^# Constraints[^\n]*$/m
  if (!heading.test(context)) return context
  return context.replace(heading, match => `${match}\n${BASE_RULES}`)
}

export function applyTaskProtocol(input: TaskInput): { contexts: number; tasks: number } {
  const batch = Array.isArray(input.tasks)
  let contexts = 0
  let tasks = 0

  if (batch) {
    let sharedPolicy = false
    if (typeof input.context === "string") {
      const before = input.context
      input.context = injectSharedConstraint(input.context)
      contexts = input.context === before ? 0 : 1
      sharedPolicy = input.context.includes(BASE_MARKER)
    }
    if (!sharedPolicy) {
      for (const raw of input.tasks as unknown[]) {
        if (!raw || typeof raw !== "object" || Array.isArray(raw)) continue
        tasks += applyItemProtocol(raw as TaskItem)
      }
    }
    return { contexts, tasks }
  }

  if (typeof input.task === "string") {
    const before = input.task
    input.task = prefixOnce(input.task, BASE_MARKER, BASE_RULES)
    tasks = input.task === before ? 0 : 1
  }
  return { contexts, tasks }
}

export default function workerOutputPolicy(pi: ExtensionAPI) {
  if (process.env.OMP_WORKER_POLICY_DISABLED === "1") {
    setExtensionHealth("worker-policy", { state: "disabled", detail: "OMP_WORKER_POLICY_DISABLED=1" })
    return
  }

  setExtensionHealth("worker-policy", { state: "loaded", detail: `${BASE_MARKER} zh-CN system policy` })
  pi.on("tool_call", async event => {
    if (!isToolCallEventType<"task", TaskInput>("task", event)) return
    const applied = applyTaskProtocol(event.input)
    incrementExtensionCounter("worker-policy", "calls")
    if (applied.contexts > 0) incrementExtensionCounter("worker-policy", "contexts", applied.contexts)
    if (applied.tasks > 0) incrementExtensionCounter("worker-policy", "task-overrides", applied.tasks)
  })
}
