# opencode-overrides

Rewrites model fields in `~/.opencode/opencode.json` in place. That file is
installed and managed by ECC and ships with hardcoded `anthropic/*` models;
this tool is the single sanctioned way to point it at the models we actually
use. There is no copy or env-var layer between the rules and the target — the
only file ever modified on this machine is `~/.opencode/opencode.json` itself.
`~/bin/ocor` is a convenience symlink to the entry script, nothing more.

## Files

| File | Role |
| --- | --- |
| `overrides.json` | rule source of truth, maintained by the CLI (not by hand), tracked in git |
| `apply.sh` | entry point (resolve symlinks, delegate to node) |
| `apply.js` | logic |

## Usage

Preferred: `ocor` (install once with `bash apply.sh link`, creates
`~/bin/ocor`; `~/bin` is not managed by this repo, so re-run `link` after
re-cloning dotfiles on a new machine). Both forms below are equivalent.

```bash
ocor                                                     # apply current rules
ocor set pytrio/gpt-5.6-sol                              # global model (not small_model)
ocor set-small pytrio/gpt-5.6-sol
ocor set-agent planner zhipuai-coding-plan/glm-5.3
ocor unset-agent planner
ocor show                                                # rules vs live target, drift marked
ocor models                                             # effective models in target, grouped
```

`set` updates `model` + `agents."*"`; `small_model` is managed independently
via `set-small`. Per-agent rules beat `"*"`. After any change, fully restart
OpenCode and verify:

```bash
opencode debug config | rg -i model
opencode debug agent build
```

## When to re-run

After `ecc repair`, `ecc auto-update`, or reinstalling ECC — anything that may
restore `~/.opencode/opencode.json` to factory state. `ecc doctor` reporting
drift on that file is expected.

Warning: `ecc repair` restores the full factory file, which also drops the
manual merge of the `opencode-models-discovery` plugin entry and any other
hand edits. Re-merge those first, then re-run `apply.sh`.

## What apply touches

Only `model`, `small_model`, and `agent.*.model`. Everything else — plugin
entries, instructions, commands, permissions, key order, 2-space indent — is
preserved byte-for-byte semantics via surgical rewrite.
