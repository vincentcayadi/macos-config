import { describe, expect, test } from "bun:test"
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import deterministicCheck, { changedFiles, packageScriptArgs } from "./index"

type RegisteredTool = {
  parameters: unknown
  execute: (...args: unknown[]) => Promise<{ content: Array<{ text: string }>; details: { reason: string } }>
}

describe("check extension", () => {
  test("keeps deleted files so project-level checks still run", async () => {
    const pi = {
      exec: async (_command: string, args: string[]) => {
        if (args[0] === "diff") return { code: 0, stdout: "src/deleted.ts\n", stderr: "" }
        return { code: 0, stdout: "", stderr: "" }
      },
    }
    expect(await changedFiles(pi as never, "/repo")).toEqual(["src/deleted.ts"])
  })

  test("builds package-manager-specific script arguments", () => {
    expect(packageScriptArgs("npm", "/repo", "/repo/app", "test")).toEqual(["--prefix", "/repo/app", "run", "test"])
    expect(packageScriptArgs("pnpm", "/repo", "/repo/app", "test")).toEqual(["--dir", "/repo/app", "run", "test"])
    expect(packageScriptArgs("yarn", "/repo", "/repo/app", "test")).toEqual(["--cwd", "/repo/app", "test"])
    expect(packageScriptArgs("bun", "/repo", "/repo/app", "test")).toEqual(["--cwd", "/repo/app", "run", "test"])
    expect(packageScriptArgs("npm", "/repo", "/repo", "test")).toEqual(["run", "test"])
  })

  test("passes only changed Python files to Ruff", async () => {
    const root = mkdtempSync(join(tmpdir(), "check-ruff-"))
    try {
      mkdirSync(join(root, "src"))
      writeFileSync(join(root, "pyproject.toml"), "[tool.ruff]\n")
      writeFileSync(join(root, "src/changed.py"), "value=1\n")
      writeFileSync(join(root, "src/untouched.py"), "value = 2\n")

      let tool: RegisteredTool | undefined
      const invocations: Array<{ command: string; args: string[] }> = []
      const schema = { optional() { return this }, describe() { return this } }
      const pi = {
        zod: { string: () => ({ ...schema }), object: (value: unknown) => value },
        registerTool(definition: RegisteredTool) { tool = definition },
        exec: async (command: string, args: string[]) => {
          if (command === "git" && args[0] === "rev-parse") return { code: 0, stdout: `${root}\n`, stderr: "" }
          if (command === "git" && args[0] === "diff") return { code: 0, stdout: "src/changed.py\n", stderr: "" }
          if (command === "git") return { code: 0, stdout: "", stderr: "" }
          if (command === "sh") return { code: 0, stdout: "", stderr: "" }
          invocations.push({ command, args })
          return { code: 0, stdout: "", stderr: "" }
        },
      }
      deterministicCheck(pi as never)
      if (!tool) throw new Error("check tool was not registered")
      expect(tool.parameters).toEqual({})
      await tool.execute("id", {}, undefined, undefined, { cwd: root })

      expect(invocations).toEqual([
        { command: "ruff", args: ["check", "src/changed.py"] },
        { command: "ruff", args: ["format", "--check", "src/changed.py"] },
      ])
    } finally {
      rmSync(root, { recursive: true, force: true })
    }
  })

  test("bypasses whole-project format scripts for changed files", async () => {
    const root = mkdtempSync(join(tmpdir(), "check-prettier-"))
    try {
      mkdirSync(join(root, "src"))
      mkdirSync(join(root, "node_modules/.bin"), { recursive: true })
      writeFileSync(join(root, "package.json"), JSON.stringify({
        scripts: { "format:check": "prettier --check ." },
        devDependencies: { prettier: "1.0.0" },
      }))
      writeFileSync(join(root, "src/changed.ts"), "export const changed=true\n")
      writeFileSync(join(root, "src/untouched.ts"), "export const untouched = true\n")
      writeFileSync(join(root, "node_modules/.bin/prettier"), "")

      let tool: RegisteredTool | undefined
      const invocations: Array<{ command: string; args: string[] }> = []
      const schema = { optional() { return this }, describe() { return this } }
      const pi = {
        zod: { string: () => ({ ...schema }), object: (value: unknown) => value },
        registerTool(definition: RegisteredTool) { tool = definition },
        exec: async (command: string, args: string[]) => {
          if (command === "git" && args[0] === "rev-parse") return { code: 0, stdout: `${root}\n`, stderr: "" }
          if (command === "git" && args[0] === "diff") return { code: 0, stdout: "src/changed.ts\n", stderr: "" }
          if (command === "git") return { code: 0, stdout: "", stderr: "" }
          if (command === "sh") return { code: 0, stdout: "", stderr: "" }
          invocations.push({ command, args })
          return { code: 0, stdout: "", stderr: "" }
        },
      }
      deterministicCheck(pi as never)
      if (!tool) throw new Error("check tool was not registered")
      await tool.execute("id", {}, undefined, undefined, { cwd: root })

      expect(invocations).toHaveLength(1)
      expect(invocations[0].command).toEndWith("/node_modules/.bin/prettier")
      expect(invocations[0].args).toEqual(["--check", "src/changed.ts"])
    } finally {
      rmSync(root, { recursive: true, force: true })
    }
  })

  test("runs Pytest when only Python project configuration changed", async () => {
    const root = mkdtempSync(join(tmpdir(), "check-pytest-"))
    try {
      writeFileSync(join(root, "pyproject.toml"), "[tool.pytest.ini_options]\n")

      let tool: RegisteredTool | undefined
      const invocations: Array<{ command: string; args: string[] }> = []
      const schema = { optional() { return this }, describe() { return this } }
      const pi = {
        zod: { string: () => ({ ...schema }), object: (value: unknown) => value },
        registerTool(definition: RegisteredTool) { tool = definition },
        exec: async (command: string, args: string[]) => {
          if (command === "git" && args[0] === "rev-parse") return { code: 0, stdout: `${root}\n`, stderr: "" }
          if (command === "git" && args[0] === "diff") return { code: 0, stdout: "pyproject.toml\n", stderr: "" }
          if (command === "git") return { code: 0, stdout: "", stderr: "" }
          if (command === "sh") return { code: 0, stdout: "", stderr: "" }
          invocations.push({ command, args })
          return { code: 0, stdout: "", stderr: "" }
        },
      }
      deterministicCheck(pi as never)
      if (!tool) throw new Error("check tool was not registered")
      expect(tool.parameters).toEqual({})
      await tool.execute("id", {}, undefined, undefined, { cwd: root })

      expect(invocations).toEqual([{ command: "pytest", args: ["-q"] }])
    } finally {
      rmSync(root, { recursive: true, force: true })
    }
  })

  test("runs Biome and Bun tests for an affected project", async () => {
    const root = mkdtempSync(join(tmpdir(), "check-biome-bun-"))
    try {
      mkdirSync(join(root, "src"))
      mkdirSync(join(root, "node_modules/.bin"), { recursive: true })
      writeFileSync(join(root, "package.json"), JSON.stringify({
        scripts: { test: "bun test" },
        devDependencies: { "@biomejs/biome": "1.0.0" },
      }))
      writeFileSync(join(root, "bun.lock"), "")
      writeFileSync(join(root, "src/changed.ts"), "export const changed=true\n")
      writeFileSync(join(root, "node_modules/.bin/biome"), "")

      let tool: RegisteredTool | undefined
      const invocations: Array<{ command: string; args: string[] }> = []
      const schema = { optional() { return this }, describe() { return this } }
      const pi = {
        zod: { string: () => ({ ...schema }), object: (value: unknown) => value },
        registerTool(definition: RegisteredTool) { tool = definition },
        exec: async (command: string, args: string[]) => {
          if (command === "git" && args[0] === "rev-parse") return { code: 0, stdout: `${root}\n`, stderr: "" }
          if (command === "git" && args[0] === "diff") return { code: 0, stdout: "src/changed.ts\n", stderr: "" }
          if (command === "git") return { code: 0, stdout: "", stderr: "" }
          if (command === "sh") return { code: 0, stdout: "", stderr: "" }
          invocations.push({ command, args })
          return { code: 0, stdout: "", stderr: "" }
        },
      }
      deterministicCheck(pi as never)
      if (!tool) throw new Error("check tool was not registered")
      await tool.execute("id", {}, undefined, undefined, { cwd: root })

      expect(invocations).toHaveLength(2)
      expect(invocations[0].command).toEndWith("/node_modules/.bin/biome")
      expect(invocations[0].args).toEqual(["check", "src/changed.ts"])
      expect(invocations[1]).toEqual({ command: "bun", args: ["run", "test"] })
    } finally {
      rmSync(root, { recursive: true, force: true })
    }
  })

  test("reports a non-Git directory explicitly", async () => {
    let tool: RegisteredTool | undefined
    const schema = {
      optional() { return this },
      describe() { return this },
    }
    const pi = {
      zod: { string: () => ({ ...schema }), object: (value: unknown) => value },
      registerTool(definition: RegisteredTool) { tool = definition },
      exec: async () => ({ code: 1, stdout: "", stderr: "not a git repository" }),
    }
    deterministicCheck(pi as never)
    if (!tool) throw new Error("check tool was not registered")
    const result = await tool.execute("id", {}, undefined, undefined, { cwd: "/tmp/no-repo" })
    expect(result.content[0].text).toContain("not inside a Git repository")
    expect(result.details.reason).toBe("not-git-repository")
  })
})
