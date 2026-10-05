// Follow the tinty (tinted-theming) scheme live.
//
// Reads <tinty-data>/current_scheme, converts the applied base16/base24
// palette into an opencode theme named "tinty-<system>-<slug>", installs it
// and re-applies whenever the scheme changes (poll). dark and light variants
// carry the same colors, so background auto-detection (unreliable inside
// tmux) becomes irrelevant. Requires tinty; without one this plugin is inert
// and the tui.json default theme stays.
//
// Declared in tui.json under "plugin" (TUI plugins must be listed there;
// there is no directory auto-discovery). Generated theme files under
// ~/.config/opencode/themes/tinty-*.json are runtime artifacts.

import fs from "node:fs"
import path from "node:path"

const POLL_MS = 3000
const PREFIX = "tinty-"

const DATA_DIR = `${process.env.XDG_DATA_HOME || `${process.env.HOME}/.local/share`}/tinted-theming/tinty`
const THEMES_DIR = `${process.env.XDG_CONFIG_HOME || `${process.env.HOME}/.config`}/opencode/themes`

// base16/base24 scheme ids look like "<system>-<slug>" e.g.
// base16-catppuccin-frappe. Slugs may themselves contain dashes.
export function parseSchemeId(id) {
  const match = /^(base16|base24|tinted8)-(.+)$/.exec(String(id || "").trim())
  return match ? { system: match[1], slug: match[2] } : undefined
}

// One theme file per scheme; palettes are immutable, so re-installing an
// existing name (install() copies only when the destination is missing)
// never serves stale colors.
export function themeNameFor(parsed) {
  const slug = String(parsed.slug).toLowerCase().replace(/[^a-z0-9-]+/g, "-")
  return `${PREFIX}${parsed.system}-${slug}`
}

// Scheme YAML stores the palette under a `palette:` block as
//   base00: "#eff1f5" # base
// Accept quoted or bare hex, ignore trailing comments.
export function parsePalette(yaml) {
  const palette = {}
  for (const match of String(yaml).matchAll(/^\s*base([0-9a-fA-F]{2})\s*:\s*["']?#([0-9a-fA-F]{6})["']?/gm)) {
    palette[`base${match[1].toLowerCase()}`] = `#${match[2].toLowerCase()}`
  }
  return Object.keys(palette).length === 16 ? palette : undefined
}

// Map the 16 base16 colors onto opencode theme keys; dark/light values stay
// identical so the TUI mode never changes the outcome. Diff backgrounds are
// pre-blended opaque — raw #rrggbbaa renders inconsistently across glyph and
// empty cells, splitting one line into two shades (see docs/theming.md):
// body = accent over base00, gutter = accent over base01. Strength follows
// scheme lightness (base00 luminance >= 128 is light: those accents are
// mid-dark colors where a heavy blend swallows the dark text); delta.sh
// mirrors the rule.
export function buildTheme(palette) {
  const c = (key) => palette[key]
  const luminance = (key) => {
    const h = palette[key].slice(1)
    const part = (i) => Number.parseInt(h.slice(i, i + 2), 16)
    return (2126 * part(0) + 7152 * part(2) + 722 * part(4)) / 10000
  }
  const alpha = luminance("base00") >= 128 ? 0.15 : 0.6
  const mix = (baseKey, accentKey, blend) => {
    const b = palette[baseKey].slice(1)
    const x = palette[accentKey].slice(1)
    const part = (i) =>
      Math.round(Number.parseInt(x.slice(i, i + 2), 16) * blend + Number.parseInt(b.slice(i, i + 2), 16) * (1 - blend))
        .toString(16)
        .padStart(2, "0")
    return `#${part(0)}${part(2)}${part(4)}`
  }
  const pair = (value) => ({ dark: value, light: value })
  const entries = {
    primary: c("base0d"),
    secondary: c("base0e"),
    accent: c("base0f"),
    error: c("base08"),
    warning: c("base09"),
    success: c("base0b"),
    info: c("base0c"),
    text: c("base05"),
    textMuted: c("base03"),
    background: c("base00"),
    backgroundPanel: c("base01"),
    backgroundElement: c("base02"),
    border: c("base02"),
    borderActive: c("base04"),
    borderSubtle: c("base01"),
    diffAdded: c("base0b"),
    diffRemoved: c("base08"),
    diffContext: c("base03"),
    diffHunkHeader: c("base0d"),
    diffHighlightAdded: c("base0b"),
    diffHighlightRemoved: c("base08"),
    diffAddedBg: mix("base00", "base0b", alpha),
    diffRemovedBg: mix("base00", "base08", alpha),
    diffContextBg: c("base01"),
    diffLineNumber: c("base04"),
    diffAddedLineNumberBg: mix("base01", "base0b", alpha),
    diffRemovedLineNumberBg: mix("base01", "base08", alpha),
    markdownText: c("base05"),
    markdownHeading: c("base0e"),
    markdownLink: c("base0d"),
    markdownLinkText: c("base0c"),
    markdownCode: c("base0b"),
    markdownBlockQuote: c("base0a"),
    markdownEmph: c("base0a"),
    markdownStrong: c("base09"),
    markdownHorizontalRule: c("base04"),
    markdownListItem: c("base0d"),
    markdownListEnumeration: c("base0c"),
    markdownImage: c("base0d"),
    markdownImageText: c("base0c"),
    markdownCodeBlock: c("base05"),
    syntaxComment: c("base03"),
    syntaxKeyword: c("base0e"),
    syntaxFunction: c("base0d"),
    syntaxVariable: c("base08"),
    syntaxString: c("base0b"),
    syntaxNumber: c("base09"),
    syntaxType: c("base0a"),
    syntaxOperator: c("base0c"),
    syntaxPunctuation: c("base05"),
  }
  return {
    $schema: "https://opencode.ai/theme.json",
    theme: Object.fromEntries(Object.entries(entries).map(([key, value]) => [key, pair(value)])),
  }
}

function readSchemeTheme(dataDir) {
  let id
  try {
    id = fs.readFileSync(path.join(dataDir, "current_scheme"), "utf8")
  } catch {
    return undefined
  }
  const parsed = parseSchemeId(id)
  if (!parsed) return undefined
  let yaml
  try {
    yaml = fs.readFileSync(path.join(dataDir, "repos", "schemes", parsed.system, `${parsed.slug}.yaml`), "utf8")
  } catch {
    return undefined
  }
  const palette = parsePalette(yaml)
  return palette ? { id: id.trim(), name: themeNameFor(parsed), theme: buildTheme(palette) } : undefined
}

async function apply(api, state) {
  if (!api.theme || !api.theme.set) return
  const scheme = readSchemeTheme(DATA_DIR)
  if (!scheme || scheme.id === state.applied) return
  const json = `${JSON.stringify(scheme.theme, null, 2)}\n`

  // Write the theme file directly: palettes are immutable per scheme, so an
  // idempotent overwrite is always correct and install()'s copy-only-when-
  // missing semantics can never serve stale colors. The file sits next to the
  // managed theme symlinks as a runtime artifact (like kitty's
  // current-theme.conf). install() then registers the name with the TUI.
  let themeFile
  try {
    fs.mkdirSync(THEMES_DIR, { recursive: true })
    themeFile = path.join(THEMES_DIR, `${scheme.name}.json`)
    fs.writeFileSync(themeFile, json)
  } catch {
    return
  }

  try {
    await api.theme.install(themeFile)
  } catch {}

  if (api.theme.set(scheme.name) || api.theme.selected === scheme.name) {
    state.applied = scheme.id
  }
}

export default {
  id: "riosky.tinty-theme",
  tui: async (api) => {
    const state = { applied: undefined }
    const tick = () => {
      apply(api, state).catch(() => {})
    }
    await apply(api, state).catch(() => {})
    const timer = setInterval(tick, POLL_MS)
    api.lifecycle.onDispose(() => clearInterval(timer))
  },
}
