export type ExtensionHealthEntry = {
  state: "loaded" | "disabled" | "degraded" | "error"
  detail?: string
  counters: Record<string, number>
}

const HEALTH_KEY = Symbol.for("omp.extension-health.v1")

type HealthRegistry = Map<string, ExtensionHealthEntry>

function registry(): HealthRegistry {
  const host = globalThis as Record<PropertyKey, unknown>
  const current = host[HEALTH_KEY]
  if (current instanceof Map) return current as HealthRegistry
  const created: HealthRegistry = new Map()
  host[HEALTH_KEY] = created
  return created
}

export function setExtensionHealth(
  name: string,
  patch: Partial<Omit<ExtensionHealthEntry, "counters">> & { counters?: Record<string, number> },
): void {
  const previous = registry().get(name) ?? { state: "loaded", counters: {} }
  registry().set(name, {
    ...previous,
    ...patch,
    counters: { ...previous.counters, ...patch.counters },
  })
}

export function incrementExtensionCounter(name: string, counter: string, amount = 1): void {
  const previous = registry().get(name) ?? { state: "loaded", counters: {} }
  setExtensionHealth(name, {
    counters: { [counter]: (previous.counters[counter] ?? 0) + amount },
  })
}

export function extensionHealthEntries(): Array<[string, ExtensionHealthEntry]> {
  return [...registry().entries()].sort(([left], [right]) => left.localeCompare(right))
}

export function renderExtensionHealth(entries = extensionHealthEntries()): string {
  if (entries.length === 0) return "No extensions reported health"
  return entries
    .map(([name, entry]) => {
      const counters = Object.entries(entry.counters)
        .filter(([, value]) => value !== 0)
        .map(([key, value]) => `${key}=${value}`)
        .join(" ")
      return [name, entry.state, entry.detail, counters].filter(Boolean).join(" | ")
    })
    .join("\n")
}
