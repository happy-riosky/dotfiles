const logo = {
  left: ["                   ", "█▀▀█ █▀▀█ █▀▀█ █▀▀▄", "█__█ █__█ █^^^ █__█", "▀▀▀▀ █▀▀▀ ▀▀▀▀ ▀~~▀"],
  right: ["             ▄     ", "█▀▀▀ █▀▀█ █▀▀█ █▀▀█", "█___ █__█ █__█ █^^^", "▀▀▀▀ ▀▀▀▀ ▀▀▀▀ ▀▀▀▀"],
}

const reset = "\x1b[0m"
const bold = "\x1b[1m"

function rgb(color) {
  if (color && typeof color.toInts === "function") {
    const [r, g, b] = color.toInts()
    return [r, g, b]
  }
  if (typeof color === "string" && /^#[0-9a-f]{6}$/i.test(color)) {
    return [
      Number.parseInt(color.slice(1, 3), 16),
      Number.parseInt(color.slice(3, 5), 16),
      Number.parseInt(color.slice(5, 7), 16),
    ]
  }
  throw new Error(`Unsupported theme color: ${String(color)}`)
}

function mix(background, foreground) {
  return background.map((channel, index) => Math.round(channel * 0.75 + foreground[index] * 0.25))
}

function foreground([r, g, b]) {
  return `\x1b[38;2;${r};${g};${b}m`
}

function background([r, g, b]) {
  return `\x1b[48;2;${r};${g};${b}m`
}

function wordmark(theme, pad = "") {
  const left = rgb(theme.textMuted)
  const right = rgb(theme.text)
  const base = rgb(theme.background)
  const leftShadow = mix(base, left)
  const rightShadow = mix(base, right)

  const draw = (line, text, shadow) =>
    [...line]
      .map((char) => {
        if (char === "_") return `${background(shadow)} ${reset}`
        if (char === "^") return `${foreground(text)}${background(shadow)}▀${reset}`
        if (char === "~") return `${foreground(shadow)}▀${reset}`
        if (char === " ") return " "
        return `${foreground(text)}${char}${reset}`
      })
      .join("")

  return logo.left.map((line, index) => `${pad}${draw(line, left, leftShadow)} ${draw(logo.right[index], right, rightShadow)}`)
}

function epilogue(theme, session) {
  const muted = foreground(rgb(theme.textMuted))
  const text = foreground(rgb(theme.text))
  const weak = (value) => `${muted}${value.padEnd(10, " ")}${reset}`
  const rawTitle = session.title ?? ""
  const title = rawTitle.length > 50 ? `${rawTitle.slice(0, 49)}…` : rawTitle

  return [
    ...wordmark(theme, "  "),
    "",
    `  ${weak("Session")}${bold}${text}${title}${reset}`,
    `  ${weak("Continue")}${bold}${text}opencode -s ${session.id}${reset}`,
    "",
  ].join("\n")
}

function residualCursorRows(output) {
  const columns = Math.max(1, process.stdout.columns || 80)
  const width = (line) => {
    const plain = line.replace(/\x1b\[[0-?]*[ -/]*[@-~]/g, "")
    return globalThis.Bun?.stringWidth?.(plain) ?? [...plain].length
  }
  const content = output.endsWith("\n") ? output.slice(0, -1) : output
  const contentRows = content
    .split("\n")
    .reduce((rows, line) => rows + Math.max(1, Math.ceil(width(line) / columns)), 0)

  // OpenCode writes the built-in value as `epilogue + "\n"` after plugin disposal.
  return contentRows + 1
}

export default {
  id: "riosky.epilogue-truecolor",
  tui: async (api) => {
    api.lifecycle.onDispose(() => {
      const route = api.route.current
      if (route?.name !== "session") return

      const sessionID = route.params?.sessionID
      if (!sessionID) return
      const session = api.state.session.get(sessionID)
      if (!session?.id) return

      let output
      try {
        output = epilogue(api.theme.current, session)
      } catch (error) {
        console.error("[epilogue-truecolor] failed to render epilogue", error)
        return
      }
      const exit = process.exit
      process.exit = function (code) {
        process.exit = exit
        process.stdout.write(`\x1b[${residualCursorRows(output)}A\r\x1b[0J${output}\n`)
        return exit.call(process, code)
      }
    })
  },
}
