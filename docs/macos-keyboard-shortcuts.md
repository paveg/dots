# macOS Global Keyboard Shortcut Scheme

Global hotkeys are assigned one "address" (modifier home) per functional layer,
so launcher, clipboard, voice input, and passwords never collide.

| Role                     | Key     | Owner             | How it is set                                         |
| ------------------------ | ------- | ----------------- | ----------------------------------------------------- |
| Launcher (main window)   | ⌘Space  | Raycast           | Scripted (`raycastGlobalHotkey = Command-49`)         |
| Clipboard History        | ⌃Space  | Raycast extension | Manual (Raycast UI; stored in Raycast's encrypted DB) |
| Dictation (hold to talk) | ⌥Space  | superwhisper      | App default; nothing to configure                     |
| Password Quick Access    | ⇧⌘Space | 1Password         | App default                                           |
| Autofill                 | ⌘\      | 1Password         | App default                                           |

superwhisper is the single voice-input app (VoiceOS was dropped), so all voice
lives on ⌥Space and no fn-based shortcut is needed.

## Scripted part

`home/.chezmoiscripts/run_onchange_after_configure-macos-keyboard.sh` (darwin only) writes:

- `AppleFnUsageType = 0` — fn/globe alone does nothing.
  IME switching is handled by Karabiner (left/right ⌘ alone → 英数/かな),
  so the macOS fn-based input-source switch is redundant. (Only affects the
  built-in keyboard anyway; the HHKB Fn key never reaches macOS.)
- Symbolic hotkeys 60/61 disabled — frees ⌃Space (input-source switch) for Clipboard History.
- Symbolic hotkeys 64/65 disabled — frees ⌘Space (Spotlight) for the Raycast launcher.
- `raycastGlobalHotkey = Command-49` — Raycast main window on ⌘Space
  (undocumented but stable key; falls back to setting it in Raycast UI if ignored).

## Manual part (new machine checklist)

1. Raycast → Extensions → Clipboard History → hotkey ⌃Space.
1. Restart Raycast so the scripted ⌘Space launcher hotkey takes effect;
   verify in Raycast Settings → General.
1. superwhisper: leave the record hotkey at its default ⌥Space.

No global shortcut may include fn: the HHKB Fn key is a firmware-level layer key
that never reaches macOS, so fn-based shortcuts only work on Apple keyboards.

## Known tradeoffs

- ⌃Space globally shadows in-app bindings such as VS Code completion trigger
  and Emacs `set-mark-command`.
  Acceptable in a Neovim/terminal-centric setup; revisit if that changes.
- Caps Lock is ⌃ (Karabiner), so ⌃Space is typed as Caps+Space from home row.
  On HHKB, Control is natively at that position — no remap involved.
- ⌃⌘Space is intentionally unused: it is the macOS emoji picker default.
