#!/usr/bin/env python3
"""Generate the Miryoku Karabiner complex-modifications asset from miryoku-refactor.vil.

Thumb layer-taps (built-in keyboard only; trigger keys are pure layer keys, no modifier emitted):
  hold left_command  -> L1 numbers/symbols   tap -> Tab
  hold space         -> L2 navigation        tap -> Space
  hold right_command -> L3 shifted symbols   tap -> Backspace
  hold right_option  -> L4 mouse remnant     tap -> Enter

OSM one-shot mods become hold-style modifiers. Mouse keys (KC_MS_/KC_WH_/KC_BTN)
cannot be synthesized by Karabiner and are blocked. Volume/brightness positions
are skipped. Rollback: `rules.sh disable`, or
`git restore platforms/darwin/home/.config/karabiner/karabiner.json`.
"""
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
VIL = Path(__file__).resolve().parent / "miryoku-refactor.vil"
OUT = (
    REPO
    / "platforms/darwin/home/.config/karabiner/assets/complex_modifications/miryoku.json"
)

KEYS = {
    "KC_Q": "q", "KC_W": "w", "KC_E": "e", "KC_R": "r", "KC_T": "t",
    "KC_Y": "y", "KC_U": "u", "KC_I": "i", "KC_O": "o", "KC_P": "p",
    "KC_A": "a", "KC_S": "s", "KC_D": "d", "KC_F": "f", "KC_G": "g",
    "KC_H": "h", "KC_J": "j", "KC_K": "k", "KC_L": "l", "KC_SCOLON": "semicolon",
    "KC_Z": "z", "KC_X": "x", "KC_C": "c", "KC_V": "v", "KC_B": "b",
    "KC_N": "n", "KC_M": "m", "KC_COMMA": "comma", "KC_DOT": "period", "KC_SLASH": "slash",
    "KC_1": "1", "KC_2": "2", "KC_3": "3", "KC_4": "4", "KC_5": "5",
    "KC_6": "6", "KC_7": "7", "KC_8": "8", "KC_9": "9", "KC_0": "0",
    "KC_GRAVE": "grave_accent_and_tilde", "KC_MINUS": "hyphen", "KC_EQUAL": "equal_sign",
    "KC_LBRACKET": "open_bracket", "KC_RBRACKET": "close_bracket",
    "KC_BSLASH": "backslash", "KC_QUOTE": "quote",
    "KC_TAB": "tab", "KC_SPACE": "spacebar", "KC_BSPACE": "delete_or_backspace",
    "KC_ENTER": "return_or_enter", "KC_DELETE": "delete_forward",
    "KC_ESCAPE": "escape", "KC_CAPSLOCK": "caps_lock",
    "KC_PGUP": "page_up", "KC_PGDOWN": "page_down",
    "KC_UP": "up_arrow", "KC_DOWN": "down_arrow", "KC_LEFT": "left_arrow",
    "KC_RIGHT": "right_arrow",
}
MODS = {
    "LCTL": ["left_control"], "LALT": ["left_option"],
    "LGUI": ["left_command"], "LSFT": ["left_shift"],
    "RCTL": ["right_control"], "RALT": ["right_option"],
    "RGUI": ["right_command"], "RSFT": ["right_shift"],
    "SGUI": ["left_shift", "left_command"],
    "MEH": ["left_control", "left_option", "left_shift"],
    "RCG": ["right_control", "right_command"],
}
OSM = {
    "MOD_LCTL": "left_control", "MOD_LALT": "left_option",
    "MOD_LGUI": "left_command", "MOD_LSFT": "left_shift",
    "MOD_RCTL": "right_control", "MOD_RALT": "right_option",
    "MOD_RGUI": "right_command", "MOD_RSFT": "right_shift",
}
DROP = ("KC_MS_", "KC_WH_", "KC_BTN", "KC_VOL", "KC_BRI")

TRIGGERS = {
    4: ("miryoku_l1", "left_command", "tab"),
    5: ("miryoku_l2", "spacebar", "spacebar"),
    6: ("miryoku_l3", "right_command", "delete_or_backspace"),
    7: ("miryoku_l4", "right_option", "return_or_enter"),
}
LETTER_COLS = (1, 2, 3, 4, 5, 7, 8, 9, 10, 11)
DEVICE = {"type": "device_if", "identifiers": [{"is_built_in_keyboard": True}]}
KITTY = {
    "type": "frontmost_application_if",
    "bundle_identifiers": [r"^net\.kovidgoyal\.kitty$"],
}
CHAIN_OVERRIDES = {
    (2, "e"): [{"key_code": "p", "modifiers": ["left_control", "left_option"]}],
    (2, "r"): [{"key_code": "n", "modifiers": ["left_control", "left_option"]}],
    (2, "g"): [{"key_code": "l", "modifiers": ["left_control"]}],
}

dropped = []


def parse(token):
    """Return a list of `to` events, [] for block, or None for passthrough."""
    if token == "KC_TRNS":
        return None
    if token == "KC_NO":
        return []
    if any(token.startswith(p) for p in DROP):
        dropped.append(token)
        return []
    m = re.fullmatch(r"OSM\((MOD_\w+)\)", token)
    if m:
        return [{"key_code": OSM[m.group(1)]}]
    m = re.fullmatch(r"(LCTL|LALT|LGUI|LSFT|RCTL|RALT|RGUI|RSFT|SGUI|MEH|RCG)\((\w+)\)", token)
    if m:
        key = KEYS[m.group(2)]
        return [{"key_code": key, "modifiers": MODS[m.group(1)]}]
    key = KEYS.get(token)
    if key is None:
        raise ValueError("unhandled token: " + token)
    return [{"key_code": key}]


def manip(frm, to, var=None, simultaneous=None, extra=None):
    if simultaneous:
        src = {"simultaneous": [{"key_code": k} for k in simultaneous]}
    else:
        src = {"key_code": frm}
    m = {"type": "basic", "from": src}
    if to:
        m["to"] = to
    conditions = []
    if var:
        conditions.append({"type": "variable_if", "name": var, "value": 1})
    conditions.append(DEVICE)
    if extra:
        conditions.extend(extra)
    m["conditions"] = conditions
    return m


def main():
    vil = json.loads(VIL.read_text())
    layout = vil["layout"]
    base = layout[0]
    letters = {
        (r, c): KEYS[base[r][c]]
        for r in range(3)
        for c in LETTER_COLS
    }

    rules = []
    layer_names = {
        1: "numbers/symbols",
        2: "navigation",
        3: "shifted symbols",
        4: "mouse-layer remnant",
    }
    for layer in (1, 2, 3, 4):
        var = "miryoku_l%d" % layer
        mans = []
        for c, (_v, frm, _tap) in sorted(TRIGGERS.items()):
            to = parse(layout[layer][3][c])
            if to is None:
                continue
            mans.append(manip(frm, to, var=var))
        for (r, c), key in sorted(letters.items()):
            to = parse(layout[layer][r][c])
            if to is None:
                continue
            if (layer, key) in CHAIN_OVERRIDES:
                mans.append(
                    manip(key, CHAIN_OVERRIDES[(layer, key)], var=var, extra=[KITTY])
                )
            mans.append(manip(key, to, var=var))
        rules.append(
            {
                "description": "Miryoku L%d: %s — hold %s"
                % (
                    layer,
                    layer_names[layer],
                    {
                        "miryoku_l1": "left_command",
                        "miryoku_l2": "space",
                        "miryoku_l3": "right_command",
                        "miryoku_l4": "right_option",
                    }[var],
                ),
                "manipulators": mans,
            }
        )

    mans = []
    for _c, (var, frm, tap) in sorted(TRIGGERS.items()):
        mans.append(
            {
                "type": "basic",
                "from": {"key_code": frm},
                "to": [{"set_variable": {"name": var, "value": 1}}],
                "to_if_alone": [{"key_code": tap}],
                "to_after_key_up": [{"set_variable": {"name": var, "value": 0}}],
                "conditions": [DEVICE],
            }
        )
    rules.append(
        {
            "description": "Miryoku: thumb layer-tap triggers "
            "(⌘L→L1 tap⇥, ␣→L2, ⌘R→L3 tap⌫, ⌥R→L4 tap⏎; modifiers not emitted)",
            "manipulators": mans,
        }
    )

    mans = []
    for combo in vil.get("combo", []):
        k1, k2, k3, k4, action = combo[:5]
        if k1 == "KC_NO" or k2 == "KC_NO" or k3 != "KC_NO" or k4 != "KC_NO":
            continue
        mans.append(
            manip(None, parse(action), simultaneous=[KEYS[k1], KEYS[k2]])
        )
    rules.append(
        {
            "description": "Miryoku: combos (S+D→Esc, F+J→CapsLock, D+F→⇧, J+K→⇧)",
            "manipulators": mans,
        }
    )

    asset = {
        "title": "Miryoku (built-in keyboard port)",
        "rules": rules,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(asset, indent=2, ensure_ascii=False) + "\n")

    for r in rules:
        print("%-70s %3d manipulators" % (r["description"], len(r["manipulators"])))
    if dropped:
        print("dropped (blocked, not synthesizable): %s" % ", ".join(sorted(set(dropped))))
    print("wrote %s" % OUT)


if __name__ == "__main__":
    sys.exit(main())
