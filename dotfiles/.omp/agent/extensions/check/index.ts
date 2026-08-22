import { existsSync } from "node:fs"
import { readFile, stat, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { basename, dirname, extname, isAbsolute, join, relative, resolve } from "node:path"
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent"
import { incrementExtensionCounter, setExtensionHealth } from "../shared/health"

const MAX_MODEL_CHARS = 7000
const COMMAND_TIMEOUT_MS = 180_000
const PYTHON_MARKERS = ["pyproject.toml", "ruff.toml", ".ruff.toml", "uv.lock", "poetry.lock", "pyrightconfig.json", "pytest.ini", "setup.cfg", "tox.ini"]
const NODE_MARKERS = ["package.json", "biome.json", "biome.jsonc", "tsconfig.json", "bun.lock", "bun.lockb", "package-lock.json", "pnpm-lock.yaml", "yarn.lock", ".eslintrc", ".prettierrc"]

type Runner = { command: string; prefix: string[] }
type CheckSpec = Runner & { name: string; args: string[]; cwd: string; timeout?: number }
type CheckResult = {
  name: string
  command: string
  cwd: string
  code: number
  killed: boolean
  ms: number
  output: string
}

type ProjectKind = "python" | "node"
type ProjectGroup = { kind: ProjectKind; root: string; files: string[] }

function lines(text: unknown): string[] {
  return String(text ?? "")
    .replace(/\r/g, "")
    .split("\n")
    .map(line => line.trimEnd())
    .filter(Boolean)
}

async function fileExists(path: string): Promise<boolean> {
  try {
    return (await stat(path)).isFile()
  } catch {
    return false
  }
}

async function readText(path: string): Promise<string> {
  try {
    return await readFile(path, "utf8")
  } catch {
    return ""
  }
}

async function readJson(path: string): Promise<any | undefined> {
  try {
    return JSON.parse(await readFile(path, "utf8"))
  } catch {
    return undefined
  }
}

async function commandExists(pi: ExtensionAPI, command: string, cwd: string, signal?: AbortSignal): Promise<boolean> {
  if (command.includes("/")) return fileExists(command)
  const probe = await pi.exec("sh", ["-lc", `command -v ${JSON.stringify(command)} >/dev/null 2>&1`], {
    cwd,
    timeout: 3000,
    signal,
  })
  return probe.code === 0
}

async function gitRoot(pi: ExtensionAPI, cwd: string, signal?: AbortSignal): Promise<string | undefined> {
  const result = await pi.exec("git", ["rev-parse", "--show-toplevel"], { cwd, timeout: 5000, signal })
  return result.code === 0 && result.stdout.trim() ? result.stdout.trim() : undefined
}

export async function changedFiles(pi: ExtensionAPI, root: string, signal?: AbortSignal): Promise<string[]> {
  const tracked = await pi.exec("git", ["diff", "--name-only", "--diff-filter=ACDMRTUXB", "HEAD", "--"], {
    cwd: root,
    timeout: 8000,
    signal,
  })
  const untracked = await pi.exec("git", ["ls-files", "--others", "--exclude-standard"], {
    cwd: root,
    timeout: 8000,
    signal,
  })

  const names = new Set<string>()
  if (tracked.code === 0) for (const line of lines(tracked.stdout)) names.add(line)
  if (untracked.code === 0) for (const line of lines(untracked.stdout)) names.add(line)
  return [...names]
}

function pythonFiles(files: string[]): string[] {
  return files.filter(file => [".py", ".pyi"].includes(extname(file).toLowerCase()))
}

function nodeFiles(files: string[]): string[] {
  const exts = new Set([".js", ".jsx", ".ts", ".tsx", ".mjs", ".cjs", ".mts", ".cts", ".json", ".jsonc", ".css", ".scss", ".graphql", ".gql"])
  return files.filter(file => exts.has(extname(file).toLowerCase()))
}

function isInside(root: string, path: string): boolean {
  const rel = relative(root, path)
  return rel === "" || (!rel.startsWith("..") && !isAbsolute(rel))
}

function ancestorDirs(start: string, repoRoot: string): string[] {
  const out: string[] = []
  let dir = resolve(start)
  const stop = resolve(repoRoot)
  while (isInside(stop, dir)) {
    out.push(dir)
    if (dir === stop) break
    const parent = dirname(dir)
    if (parent === dir) break
    dir = parent
  }
  return out
}

function hasAny(dir: string, names: readonly string[]): boolean {
  return names.some(name => existsSync(join(dir, name)))
}

function nearestProjectRoot(repoRoot: string, repoRelativeFile: string, kind: ProjectKind): string {
  const start = dirname(resolve(repoRoot, repoRelativeFile))
  const markers = kind === "python" ? PYTHON_MARKERS : NODE_MARKERS
  for (const dir of ancestorDirs(start, repoRoot)) {
    if (hasAny(dir, markers)) return dir
  }
  return repoRoot
}

function toProjectRelative(projectRoot: string, repoRoot: string, repoRelativeFile: string): string {
  const rel = relative(projectRoot, resolve(repoRoot, repoRelativeFile))
  return rel.split("\\").join("/") || "."
}

function groupChangedProjects(repoRoot: string, files: string[]): ProjectGroup[] {
  const groups = new Map<string, ProjectGroup>()
  const add = (kind: ProjectKind, file: string) => {
    const projectRoot = nearestProjectRoot(repoRoot, file, kind)
    const key = `${kind}:${projectRoot}`
    const group = groups.get(key) ?? { kind, root: projectRoot, files: [] }
    group.files.push(toProjectRelative(projectRoot, repoRoot, file))
    groups.set(key, group)
  }

  for (const file of files) {
    const name = basename(file)
    const pythonConfig = PYTHON_MARKERS.includes(name) || /^requirements(?:[-.].*)?\.txt$/i.test(name)
    const nodeConfig = NODE_MARKERS.includes(name) || /^tsconfig(?:\..+)?\.json$/i.test(name)
    if (pythonConfig || pythonFiles([file]).length > 0) add("python", file)
    if (nodeConfig || nodeFiles([file]).length > 0) add("node", file)
  }
  return [...groups.values()]
}

function projectLabel(repoRoot: string, projectRoot: string): string {
  const rel = relative(repoRoot, projectRoot).split("\\").join("/")
  return rel || "."
}

async function ancestorPyprojectTexts(projectRoot: string, repoRoot: string): Promise<Array<{ dir: string; text: string }>> {
  const out: Array<{ dir: string; text: string }> = []
  for (const dir of ancestorDirs(projectRoot, repoRoot)) {
    const text = await readText(join(dir, "pyproject.toml"))
    if (text) out.push({ dir, text })
  }
  return out
}

async function ruffConfigured(projectRoot: string, repoRoot: string): Promise<boolean> {
  for (const dir of ancestorDirs(projectRoot, repoRoot)) {
    if (existsSync(join(dir, "ruff.toml")) || existsSync(join(dir, ".ruff.toml"))) return true
    const text = await readText(join(dir, "pyproject.toml"))
    if (/\[tool\.ruff(?:\.|\])/.test(text) || /\bruff\b/i.test(text)) return true
  }
  return false
}

async function biomeConfigured(projectRoot: string, repoRoot: string): Promise<boolean> {
  for (const dir of ancestorDirs(projectRoot, repoRoot)) {
    if (existsSync(join(dir, "biome.json")) || existsSync(join(dir, "biome.jsonc"))) return true
    const pkg = await readJson(join(dir, "package.json"))
    if (pkg?.devDependencies?.["@biomejs/biome"] || pkg?.dependencies?.["@biomejs/biome"]) return true
  }
  return false
}

async function nodeToolConfigured(
  projectRoot: string,
  repoRoot: string,
  configNames: string[],
  packageNames: string[],
): Promise<boolean> {
  for (const dir of ancestorDirs(projectRoot, repoRoot)) {
    if (configNames.some(name => existsSync(join(dir, name)))) return true
    const pkg = await readJson(join(dir, "package.json"))
    for (const name of packageNames) {
      if (pkg?.devDependencies?.[name] || pkg?.dependencies?.[name]) return true
    }
  }
  return false
}

function packageManagerRoot(projectRoot: string, repoRoot: string): { root: string; pm: string } {
  for (const dir of ancestorDirs(projectRoot, repoRoot)) {
    if (existsSync(join(dir, "bun.lock")) || existsSync(join(dir, "bun.lockb"))) return { root: dir, pm: "bun" }
    if (existsSync(join(dir, "pnpm-lock.yaml"))) return { root: dir, pm: "pnpm" }
    if (existsSync(join(dir, "yarn.lock"))) return { root: dir, pm: "yarn" }
    if (existsSync(join(dir, "package-lock.json"))) return { root: dir, pm: "npm" }
  }
  return { root: projectRoot, pm: "npm" }
}

export function packageScriptArgs(pm: string, pmRoot: string, projectRoot: string, script: string): string[] {
  const nested = relative(pmRoot, projectRoot) !== ""
  if (pm === "npm") return nested ? ["--prefix", projectRoot, "run", script] : ["run", script]
  if (pm === "pnpm") return nested ? ["--dir", projectRoot, "run", script] : ["run", script]
  if (pm === "yarn") return nested ? ["--cwd", projectRoot, script] : [script]
  return nested ? ["--cwd", projectRoot, "run", script] : ["run", script]
}

async function packageScriptSpec(
  pi: ExtensionAPI,
  projectRoot: string,
  repoRoot: string,
  script: string,
  signal?: AbortSignal,
): Promise<CheckSpec | undefined> {
  const { root, pm } = packageManagerRoot(projectRoot, repoRoot)
  if (!await commandExists(pi, pm, root, signal)) return undefined
  return {
    name: `${pm} ${script} [${projectLabel(repoRoot, projectRoot)}]`,
    command: pm,
    prefix: [],
    cwd: root,
    args: packageScriptArgs(pm, root, projectRoot, script),
  }
}

function localBinUp(projectRoot: string, repoRoot: string, name: string): string {
  for (const dir of ancestorDirs(projectRoot, repoRoot)) {
    const path = join(dir, "node_modules", ".bin", name)
    if (existsSync(path)) return path
  }
  return name
}

async function pythonRunner(pi: ExtensionAPI, projectRoot: string, repoRoot: string, binary: string, signal?: AbortSignal): Promise<Runner | undefined> {
  for (const dir of ancestorDirs(projectRoot, repoRoot)) {
    if (existsSync(join(dir, "uv.lock")) && (await commandExists(pi, "uv", projectRoot, signal))) {
      return { command: "uv", prefix: ["run", "--project", dir, binary] }
    }
  }
  if (await commandExists(pi, binary, projectRoot, signal)) return { command: binary, prefix: [] }
  return undefined
}

async function nodeRunner(pi: ExtensionAPI, projectRoot: string, repoRoot: string, binary: string, signal?: AbortSignal): Promise<Runner | undefined> {
  const local = localBinUp(projectRoot, repoRoot, binary)
  if (local !== binary) return { command: local, prefix: [] }
  if (await commandExists(pi, binary, projectRoot, signal)) return { command: binary, prefix: [] }
  return undefined
}

async function runCheck(pi: ExtensionAPI, spec: CheckSpec, signal?: AbortSignal): Promise<CheckResult> {
  const started = Date.now()
  const result = await pi.exec(spec.command, [...spec.prefix, ...spec.args], {
    cwd: spec.cwd,
    timeout: spec.timeout ?? COMMAND_TIMEOUT_MS,
    signal,
    env: { ...process.env, NO_COLOR: "1", FORCE_COLOR: "0", CI: "1" },
  })
  return {
    name: spec.name,
    command: [spec.command, ...spec.prefix, ...spec.args].join(" "),
    cwd: spec.cwd,
    code: result.code,
    killed: Boolean(result.killed),
    ms: Date.now() - started,
    output: [result.stdout, result.stderr].filter(Boolean).join("\n").trim(),
  }
}

function compactFailure(output: string, maxLines = 30): string[] {
  const out = lines(output)
  if (out.length <= maxLines) return out
  return [...out.slice(0, maxLines), `... ${out.length - maxLines} more lines`]
}

async function saveFullOutput(results: CheckResult[]): Promise<string> {
  const body = results
    .map(result => `## ${result.name}\ncwd=${result.cwd}\n$ ${result.command}\nexit=${result.code}\n\n${result.output || "(no output)"}`)
    .join("\n\n")
  const path = join(tmpdir(), `omp-check-${process.pid}-${Date.now()}.log`)
  await writeFile(path, body, "utf8")
  return path
}

function renderResults(results: CheckResult[], repoRoot: string, fullOutputPath?: string): string {
  const out: string[] = []
  for (const result of results) {
    const ok = result.code === 0 && !result.killed
    out.push(`${ok ? "PASS" : "FAIL"} ${result.name} ${(result.ms / 1000).toFixed(1)}s cwd=${projectLabel(repoRoot, result.cwd)}`)
    if (!ok) for (const line of compactFailure(result.output)) out.push(`  ${line}`)
  }
  if (fullOutputPath) out.push(`Full output ${fullOutputPath}`)
  return out.join("\n")
}

export default function deterministicCheck(pi: ExtensionAPI) {
  const z = pi.zod
  setExtensionHealth("check", { state: "loaded", detail: "ready" })

  pi.registerTool({
    name: "check",
    label: "Check",
    description: "Zero-argument verification for agents. Detects Git-changed files, runs file-scoped static checks, and tests affected projects.",
    promptSnippet: "Call check once after edits; it discovers changed files, configured tools, and affected tests automatically.",
    promptGuidelines: [
      "Call with no arguments after completing edits; never spend tokens listing changed files.",
      "Treat the result as the verification record and do not repeat successful checks through bash.",
      "Use repository-wide commands separately only when the user or repository explicitly requires full validation.",
    ],
    loadMode: "essential",
    approval: "exec",
    strict: true,
    parameters: z.object({}),

    async execute(_toolCallId, _params, signal, _onUpdate, ctx) {
      incrementExtensionCounter("check", "runs")
      const repoRoot = await gitRoot(pi, ctx.cwd, signal)
      if (!repoRoot) {
        const text = `SKIP check: not inside a Git repository cwd=${ctx.cwd}`
        setExtensionHealth("check", { state: "degraded", detail: "last=not-git-repository" })
        return { content: [{ type: "text", text }], details: { reason: "not-git-repository" } }
      }

      const files = await changedFiles(pi, repoRoot, signal)
      if (files.length === 0) {
        const text = `SKIP check: no changed files repo=${repoRoot}`
        setExtensionHealth("check", { state: "loaded", detail: "last=no-changed-files" })
        return { content: [{ type: "text", text }], details: { repoRoot, files, reason: "no-changed-files" } }
      }

      const projects = groupChangedProjects(repoRoot, files)
      if (projects.length === 0) {
        const text = "SKIP check: changed files do not belong to a supported Python or Node project"
        setExtensionHealth("check", { state: "degraded", detail: "last=no-supported-projects" })
        return { content: [{ type: "text", text }], details: { repoRoot, files, projects, reason: "no-supported-projects" } }
      }

      const checks: CheckSpec[] = []
      const skipped: string[] = []

      for (const project of projects) {
        const label = projectLabel(repoRoot, project.root)

        if (project.kind === "python") {
          const projectFiles = project.files.filter(file => [".py", ".pyi"].includes(extname(file).toLowerCase()) && existsSync(resolve(project.root, file)))
          const pyTexts = await ancestorPyprojectTexts(project.root, repoRoot)
          const combinedPyproject = pyTexts.map(item => item.text).join("\n")

          if (projectFiles.length > 0 && await ruffConfigured(project.root, repoRoot)) {
            const ruff = await pythonRunner(pi, project.root, repoRoot, "ruff", signal)
            if (ruff) {
              checks.push({ name: `ruff check [${label}]`, ...ruff, cwd: project.root, args: ["check", ...projectFiles] })
              checks.push({ name: `ruff format [${label}]`, ...ruff, cwd: project.root, args: ["format", "--check", ...projectFiles] })
            } else skipped.push(`Ruff configured executable missing [${label}]`)
          }

          if (projectFiles.length > 0 && pyTexts.length > 0) {
            const tyConfigured = /(^|[\s"'])ty([\s"'=,]|$)/m.test(combinedPyproject)
            const pyrightConfigured =
              ancestorDirs(project.root, repoRoot).some(dir => existsSync(join(dir, "pyrightconfig.json"))) ||
              /\bpyright\b/i.test(combinedPyproject)
            if (tyConfigured) {
              const ty = await pythonRunner(pi, project.root, repoRoot, "ty", signal)
              if (ty) checks.push({ name: `ty [${label}]`, ...ty, cwd: project.root, args: ["check", ...projectFiles] })
              else skipped.push(`ty configured executable missing [${label}]`)
            } else if (pyrightConfigured) {
              const pyright = await nodeRunner(pi, project.root, repoRoot, "pyright", signal)
              if (pyright) checks.push({ name: `pyright [${label}]`, ...pyright, cwd: project.root, args: projectFiles })
              else skipped.push(`Pyright configured executable missing [${label}]`)
            }
          }

          const pythonDirs = ancestorDirs(project.root, repoRoot)
          const pytestTexts = await Promise.all(pythonDirs.flatMap(dir =>
            ["pytest.ini", "setup.cfg", "tox.ini", "requirements.txt", "requirements-dev.txt"].map(name => readText(join(dir, name))),
          ))
          const pytestConfigured = /\bpytest\b|\[tool:pytest\]|\[pytest\]/i.test([combinedPyproject, ...pytestTexts].join("\n"))
          if (pytestConfigured) {
            const pytest = await pythonRunner(pi, project.root, repoRoot, "pytest", signal)
            if (pytest) checks.push({ name: `pytest [${label}]`, ...pytest, cwd: project.root, args: ["-q"], timeout: 300_000 })
            else skipped.push(`pytest configured executable missing [${label}]`)
          }
        }

        if (project.kind === "node") {
          const packageJson = await readJson(join(project.root, "package.json"))
          const scripts = packageJson?.scripts ?? {}
          const projectFiles = nodeFiles(project.files).filter(file => existsSync(resolve(project.root, file)))
          const eslintFiles = projectFiles.filter(file => [".js", ".jsx", ".ts", ".tsx", ".mjs", ".cjs", ".mts", ".cts"].includes(extname(file).toLowerCase()))

          let biomeCovered = false
          if (projectFiles.length > 0 && await biomeConfigured(project.root, repoRoot)) {
            const biome = await nodeRunner(pi, project.root, repoRoot, "biome", signal)
            if (biome) {
              checks.push({ name: `biome check [${label}]`, ...biome, cwd: project.root, args: ["check", ...projectFiles] })
              biomeCovered = true
            } else skipped.push(`Biome configured executable missing [${label}]`)
          }

          if (!biomeCovered && eslintFiles.length > 0 && await nodeToolConfigured(
            project.root,
            repoRoot,
            ["eslint.config.js", "eslint.config.mjs", "eslint.config.cjs", ".eslintrc", ".eslintrc.json", ".eslintrc.js", ".eslintrc.cjs"],
            ["eslint"],
          )) {
            const eslint = await nodeRunner(pi, project.root, repoRoot, "eslint", signal)
            if (eslint) checks.push({ name: `eslint [${label}]`, ...eslint, cwd: project.root, args: eslintFiles })
            else skipped.push(`ESLint configured executable missing [${label}]`)
          }

          if (!biomeCovered && projectFiles.length > 0 && await nodeToolConfigured(
            project.root,
            repoRoot,
            ["prettier.config.js", "prettier.config.mjs", "prettier.config.cjs", ".prettierrc", ".prettierrc.json", ".prettierrc.js", ".prettierrc.cjs"],
            ["prettier"],
          )) {
            const prettier = await nodeRunner(pi, project.root, repoRoot, "prettier", signal)
            if (prettier) checks.push({ name: `prettier [${label}]`, ...prettier, cwd: project.root, args: ["--check", ...projectFiles] })
            else skipped.push(`Prettier configured executable missing [${label}]`)
          }

          if (scripts.typecheck) {
            const typecheck = await packageScriptSpec(pi, project.root, repoRoot, "typecheck", signal)
            if (typecheck) checks.push(typecheck)
            else skipped.push(`typecheck script exists package manager missing [${label}]`)
          } else if (existsSync(join(project.root, "tsconfig.json"))) {
            const tsc = await nodeRunner(pi, project.root, repoRoot, "tsc", signal)
            if (tsc) checks.push({ name: `tsc [${label}]`, ...tsc, cwd: project.root, args: ["--noEmit", "--pretty", "false"] })
            else skipped.push(`tsconfig.json exists tsc missing [${label}]`)
          }

          const testScript = typeof scripts.test === "string" ? scripts.test : ""
          if (testScript && !/no test specified/i.test(testScript)) {
            const test = await packageScriptSpec(pi, project.root, repoRoot, "test", signal)
            if (test) checks.push({ ...test, timeout: 300_000 })
            else skipped.push(`test script exists package manager missing [${label}]`)
          } else {
            const packageManager = packageManagerRoot(project.root, repoRoot).pm
            const declaredManager = typeof packageJson?.packageManager === "string" ? packageJson.packageManager.split("@")[0] : ""
            if (packageManager === "bun" || declaredManager === "bun") {
              const bun = await commandExists(pi, "bun", project.root, signal)
              if (bun) checks.push({ name: `bun test [${label}]`, command: "bun", prefix: [], cwd: project.root, args: ["test"], timeout: 300_000 })
              else skipped.push(`Bun project test runner missing [${label}]`)
            }
          }
        }
      }

      if (checks.length === 0) {
        const text = [
          "SKIP check: affected projects have no configured verifiers",
          `Projects ${projects.map(project => `${project.kind}:${projectLabel(repoRoot, project.root)}`).join(" ")}`,
          ...skipped.map(item => `SKIP ${item}`),
        ].join("\n")
        setExtensionHealth("check", { state: "degraded", detail: "last=no-configured-verifiers" })
        return { content: [{ type: "text", text }], details: { repoRoot, files, projects, skipped, reason: "no-configured-verifiers", checks: [] } }
      }

      const results: CheckResult[] = []
      for (const spec of checks) {
        if (signal?.aborted) break
        results.push(await runCheck(pi, spec, signal))
      }

      const rawChars = results.reduce((sum, result) => sum + result.output.length, 0)
      const failed = results.some(result => result.code !== 0 || result.killed)
      const fullOutputPath = rawChars > MAX_MODEL_CHARS || failed ? await saveFullOutput(results) : undefined
      const text = [renderResults(results, repoRoot, fullOutputPath), ...skipped.map(item => `SKIP ${item}`)]
        .filter(Boolean)
        .join("\n")
      setExtensionHealth("check", { state: failed ? "degraded" : "loaded", detail: `last=${failed ? "failed" : "passed"} checks=${results.length}` })
      incrementExtensionCounter("check", "checks", results.length)
      if (failed) incrementExtensionCounter("check", "failures")

      return {
        content: [{ type: "text", text: text.slice(0, MAX_MODEL_CHARS) }],
        details: {
          repoRoot,
          files,
          projects,
          skipped,
          failed,
          fullOutputPath,
          checks: results.map(({ output, ...result }) => result),
        },
      }
    },
  })
}
