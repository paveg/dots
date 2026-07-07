#!/bin/bash
# Configure the macOS global-hotkey layer so launcher, clipboard history,
# and voice-input apps stop colliding. Full scheme (including the manual,
# non-scriptable pieces) is documented in docs/macos-keyboard-shortcuts.md.
#
# Triggered on chezmoi apply when this script changes.

set -euo pipefail

# fn/globe alone does nothing; IME switching is Karabiner's job
# (left/right cmd alone -> eisuu/kana)
defaults write com.apple.HIToolbox AppleFnUsageType -int 0

# Free the key slots the scheme needs:
#   60/61 = input-source switch (ctrl-space / ctrl-opt-space)
#   64/65 = Spotlight / Finder search (cmd-space / cmd-opt-space)
for id in 60 61 64 65; do
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys \
    -dict-add "$id" '<dict><key>enabled</key><false/></dict>'
done

# Raycast main window on cmd-space (49 = space keycode).
# Clipboard History lives on ctrl-space, set manually in the Raycast UI.
# Takes effect after Raycast restarts.
if [ -d "/Applications/Raycast.app" ]; then
  defaults write com.raycast.macos raycastGlobalHotkey -string "Command-49"
fi

# Flush the symbolic-hotkey cache so changes apply without re-login
activate_settings="/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"
if [ -x "$activate_settings" ]; then
  "$activate_settings" -u
fi
