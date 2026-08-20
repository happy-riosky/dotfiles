#!/usr/bin/env node

const fs = require("node:fs")
const os = require("node:os")
const path = require("node:path")

const SCRIPT_DIR = fs.realpathSync(__dirname)
const RULES_PATH = path.join(SCRIPT_DIR, "overrides.json")
const TARGET_PATH = path.join(os.homedir(), ".opencode", "opencode.json")
const BIN_DIR = path.join(os.homedir(), "bin")
const LINK_PATH = path.join(BIN_DIR, "ocor")
const MODEL_RE = /^[A-Za-z0-9][A-Za-z0-9._-]*\/[A-Za-z0-9][A-Za-z0-9._-]*$/

const USAGE = `usage: apply.sh <command> [args]

commands:
  apply                          rewrite ~/.opencode/opencode.json from overrides.json
  set <provider/model>           set model + agents."*", then apply (small_model untouched)
  set-small <provider/model>     set small_model only, then apply
  set-agent <name> <provider/model>
                                 set a per-agent override (beats "*"), then apply
  unset-agent <name>             remove a per-agent override, then apply
  show                           print rules and live target state, mark drift
  models                         list effective models in the target, grouped
  link                           install ~/bin/ocor symlink to this tool
  help                           print this usage

paths:
  rules:  ${RULES_PATH}
  target: ${TARGET_PATH}`

function fail(msg) {
  process.stderr.write(`error: ${msg}\n`)
  process.exit(1)
}

function usageFail(msg) {
  process.stderr.write(`error: ${msg}\n\n${USAGE}\n`)
  process.exit(2)
}

function warn(msg) {
  process.stderr.write(`warning: ${msg}\n`)
}

function info(msg) {
  process.stdout.write(`${msg}\n`)
}

function parseArgv(argv) {
  const rest = []
  for (const arg of argv) {
    if (arg === "--help" || arg === "-h") {
      info(USAGE)
      process.exit(0)
    } else {
      rest.push(arg)
    }
  }
  return rest
}

function readJsonFile(file, label) {
  let raw
  try {
    raw = fs.readFileSync(file, "utf8")
  } catch (err) {
    throw new Error(`cannot read ${label} (${file}): ${err.message}`)
  }
  try {
    return JSON.parse(raw)
  } catch (err) {
    throw new Error(`invalid JSON in ${label} (${file}): ${err.message}`)
  }
}

function tryReadTarget() {
  try {
    return readJsonFile(TARGET_PATH, "target config")
  } catch (err) {
    warn(err.message)
    return null
  }
}

function serializeJson(obj) {
  return JSON.stringify(obj, null, 2) + "\n"
}

function validateModel(value, label) {
  if (typeof value !== "string" || !MODEL_RE.test(value)) {
    throw new Error(`${label} must look like provider/model, got: ${JSON.stringify(value)}`)
  }
}

function loadRules() {
  const rules = readJsonFile(RULES_PATH, "overrides.json")
  if (typeof rules !== "object" || rules === null || Array.isArray(rules)) {
    throw new Error("overrides.json must contain a JSON object")
  }
  if (rules.model !== undefined) validateModel(rules.model, "model")
  if (rules.small_model !== undefined) validateModel(rules.small_model, "small_model")
  if (typeof rules.agents !== "object" || rules.agents === null || Array.isArray(rules.agents)) {
    throw new Error('overrides.json must contain an agents object with a "*" default')
  }
  if (!Object.prototype.hasOwnProperty.call(rules.agents, "*")) {
    throw new Error('overrides.json agents must include a "*" default')
  }
  validateModel(rules.agents["*"], 'agents."*"')
  for (const [name, model] of Object.entries(rules.agents)) {
    if (name !== "*") validateModel(model, `agents."${name}"`)
  }
  return rules
}

function writeRules(rules) {
  const out = serializeJson(rules)
  JSON.parse(out)
  fs.writeFileSync(RULES_PATH, out, "utf8")
}

function fmt(value) {
  return value === undefined ? "(unset)" : String(value)
}

function reorderTopLevel(target) {
  const head = ["$schema", "model", "small_model"]
  const rest = Object.entries(target).filter(([key]) => !head.includes(key))
  const next = {}
  for (const key of head) {
    if (Object.prototype.hasOwnProperty.call(target, key)) next[key] = target[key]
  }
  for (const [key, value] of rest) next[key] = value
  for (const key of Object.keys(target)) delete target[key]
  Object.assign(target, next)
}

function setTopLevel(target, key, value) {
  const existed = Object.prototype.hasOwnProperty.call(target, key)
  target[key] = value
  if (!existed) reorderTopLevel(target)
}

function effectiveAgentModel(rules, name) {
  if (Object.prototype.hasOwnProperty.call(rules.agents, name)) return rules.agents[name]
  return rules.agents["*"]
}

function applyToTarget(rules) {
  const target = readJsonFile(TARGET_PATH, "target config")
  const changes = []

  if (rules.model !== undefined && target.model !== rules.model) {
    changes.push(`model: ${fmt(target.model)} -> ${rules.model}`)
    setTopLevel(target, "model", rules.model)
  }
  if (rules.small_model !== undefined && target.small_model !== rules.small_model) {
    changes.push(`small_model: ${fmt(target.small_model)} -> ${rules.small_model}`)
    setTopLevel(target, "small_model", rules.small_model)
  }

  if (typeof target.agent === "object" && target.agent !== null) {
    for (const [name, def] of Object.entries(target.agent)) {
      if (typeof def !== "object" || def === null) continue
      const wanted = effectiveAgentModel(rules, name)
      if (def.model !== wanted) {
        changes.push(`agent.${name}.model: ${fmt(def.model)} -> ${wanted}`)
        def.model = wanted
      }
    }
  } else {
    warn("target has no agent object; only model/small_model were considered")
  }

  if (changes.length === 0) {
    info(`target already matches rules (${TARGET_PATH})`)
    return
  }
  for (const change of changes) info(`  ${change}`)
  const out = serializeJson(target)
  JSON.parse(out)
  fs.writeFileSync(TARGET_PATH, out, "utf8")
  info(`applied ${changes.length} change(s) to ${TARGET_PATH}`)
}

function cmdApply() {
  applyToTarget(loadRules())
}

function cmdSet(model) {
  validateModel(model, "model argument")
  const rules = loadRules()
  rules.model = model
  rules.agents["*"] = model
  writeRules(rules)
  applyToTarget(rules)
}

function cmdSetSmall(model) {
  validateModel(model, "model argument")
  const rules = loadRules()
  rules.small_model = model
  writeRules(rules)
  applyToTarget(rules)
}

function cmdSetAgent(name, model) {
  if (!name) usageFail("set-agent requires <name> <provider/model>")
  validateModel(model, "model argument")
  const rules = loadRules()
  const target = tryReadTarget()
  if (target && typeof target.agent === "object" && target.agent !== null) {
    const known = Object.keys(target.agent)
    if (!known.includes(name)) {
      warn(`agent "${name}" not found in target (known: ${known.join(", ") || "none"}); rule persisted anyway`)
    }
  }
  rules.agents[name] = model
  writeRules(rules)
  applyToTarget(rules)
}

function cmdUnsetAgent(name) {
  if (!name) usageFail("unset-agent requires <name>")
  if (name === "*") usageFail('cannot unset "*"')
  const rules = loadRules()
  if (!Object.prototype.hasOwnProperty.call(rules.agents, name)) {
    info(`no per-agent rule for "${name}"; nothing to remove`)
    return
  }
  delete rules.agents[name]
  writeRules(rules)
  applyToTarget(rules)
}

function mark(label, actual, expected) {
  const ok = actual === expected
  info(`  ${label.padEnd(32)} ${fmt(actual)}${ok ? "" : `  [drift -> ${expected}]`}`)
}

function cmdShow() {
  const rules = loadRules()
  info(`rules: ${RULES_PATH}`)
  info(`  model:        ${fmt(rules.model)}`)
  info(`  small_model:  ${fmt(rules.small_model)}`)
  info(`  agents."*":   ${rules.agents["*"]}`)
  for (const [name, model] of Object.entries(rules.agents)) {
    if (name !== "*") info(`  agents."${name}": ${model}`)
  }
  info("")
  const target = tryReadTarget()
  if (!target) return
  info(`target: ${TARGET_PATH}`)
  if (rules.model === undefined) {
    info(`  model                           ${fmt(target.model)} (rule: unset)`)
  } else {
    mark("model", target.model, rules.model)
  }
  if (rules.small_model === undefined) {
    info(`  small_model                     ${fmt(target.small_model)} (rule: unset)`)
  } else {
    mark("small_model", target.small_model, rules.small_model)
  }
  if (typeof target.agent === "object" && target.agent !== null) {
    for (const [name, def] of Object.entries(target.agent)) {
      if (typeof def !== "object" || def === null) continue
      mark(`agent.${name}.model`, def.model, effectiveAgentModel(rules, name))
    }
  }
}

function cmdModels() {
  const target = tryReadTarget()
  if (!target) process.exit(1)
  info(`target: ${TARGET_PATH}`)
  info(`  model:        ${fmt(target.model)}`)
  info(`  small_model:  ${fmt(target.small_model)}`)
  const groups = {}
  let count = 0
  if (typeof target.agent === "object" && target.agent !== null) {
    for (const [name, def] of Object.entries(target.agent)) {
      if (typeof def !== "object" || def === null) continue
      const model = fmt(def.model)
      if (!Object.prototype.hasOwnProperty.call(groups, model)) groups[model] = []
      groups[model].push(name)
      count++
    }
  }
  info(`  agents (${count}):`)
  for (const [model, names] of Object.entries(groups)) {
    info(`    ${model} x ${names.length}: ${names.join(", ")}`)
  }
}

function cmdLink() {
  const scriptPath = path.join(SCRIPT_DIR, "apply.sh")
  if (!fs.existsSync(scriptPath)) {
    throw new Error(`entry script not found: ${scriptPath}`)
  }
  let lstat = null
  try {
    lstat = fs.lstatSync(LINK_PATH)
  } catch {
    // absent, fall through to creation
  }
  if (lstat) {
    if (lstat.isSymbolicLink()) {
      const existing = fs.readlinkSync(LINK_PATH)
      const resolved = path.resolve(BIN_DIR, existing)
      let resolvedReal = null
      try {
        resolvedReal = fs.realpathSync(resolved)
      } catch {
        // dangling link, fall through to refusal below
      }
      if (resolvedReal !== null && resolvedReal === fs.realpathSync(scriptPath)) {
        info(`already linked: ${LINK_PATH} -> ${existing}`)
        return
      }
      fail(`refusing to overwrite ${LINK_PATH} (points to ${existing}); remove it first if intentional`)
    }
    fail(`refusing to overwrite ${LINK_PATH} (not a symlink); remove it first if intentional`)
  }
  fs.mkdirSync(BIN_DIR, { recursive: true })
  fs.symlinkSync(scriptPath, LINK_PATH)
  info(`linked: ${LINK_PATH} -> ${scriptPath}`)
}

function expectArgs(args, count, usage) {
  if (args.length !== count) {
    usageFail(`${usage}: expected ${count} argument(s), got ${args.length}`)
  }
}

function main() {
  const rest = parseArgv(process.argv.slice(2))
  const command = rest.length > 0 ? rest[0] : "apply"
  const args = rest.slice(1)
  try {
    switch (command) {
      case "apply":
        expectArgs(args, 0, "apply")
        cmdApply()
        break
      case "set":
        expectArgs(args, 1, "set <provider/model>")
        cmdSet(args[0])
        break
      case "set-small":
        expectArgs(args, 1, "set-small <provider/model>")
        cmdSetSmall(args[0])
        break
      case "set-agent":
        expectArgs(args, 2, "set-agent <name> <provider/model>")
        cmdSetAgent(args[0], args[1])
        break
      case "unset-agent":
        expectArgs(args, 1, "unset-agent <name>")
        cmdUnsetAgent(args[0])
        break
      case "show":
        expectArgs(args, 0, "show")
        cmdShow()
        break
      case "models":
        expectArgs(args, 0, "models")
        cmdModels()
        break
      case "link":
        expectArgs(args, 0, "link")
        cmdLink()
        break
      case "help":
        expectArgs(args, 0, "help")
        info(USAGE)
        break
      default:
        usageFail(`unknown command: ${command}`)
    }
  } catch (err) {
    fail(err.message)
  }
}

main()
