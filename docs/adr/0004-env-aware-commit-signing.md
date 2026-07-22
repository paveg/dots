# 0004. Machine-scoped commit signing (1Password on work, on-disk key on personal)

## Status

Accepted — 2026-07-23. Closes issue #196.

## Context

Commit signing hardcoded the 1Password GUI signer, so it could not sign on a headless / SSH session (`dot_config/git/main.tmpl` set `gpg.ssh.program = op-ssh-sign` on all of macOS). `op-ssh-sign` needs the 1Password desktop app unlocked, and there is no headless unlock, so `git commit` failed with `error: 1Password: failed to fill whole buffer` or fell back to an Unverified signature.

Two keys are already present:

- `N4Wn` — held inside 1Password (private key never on disk). Maximum at-rest protection; requires the GUI to sign.
- `Sl3q` — `~/.ssh/id_ed25519`, no passphrase, already registered on GitHub as an **auth** key. Signs headlessly, but is exposed at rest on disk.

The repository already splits configuration by machine through the `.business_use` chezmoi variable.

## Decision

Choose the signer per machine at chezmoi-apply time (not at commit time), keyed on `.business_use`:

- **business (+ macOS)** — `gpg.ssh.program = op-ssh-sign`, `signingkey = N4Wn`. The signing key never touches disk.
- **personal** — no `gpg.ssh.program` (git's default `ssh-keygen` signer), `signingkey = ~/.ssh/id_ed25519.pub` (`Sl3q`). Signs on both headless and GUI sessions, so personal commits are always Verified.
- Both — `gpg.ssh.allowedSignersFile = ~/.config/git/allowed_signers`, listing `Sl3q` and `N4Wn` under the personal and work emails, so `git log --show-signature` verifies locally regardless of which key signed.

### Rejected alternatives

- **Runtime env-aware dual-key on personal** (1Password on GUI, on-disk on headless): git passes a single `user.signingkey` to the signer, and the two signers need different keys (`N4Wn` vs `Sl3q`), so switching both program and key at commit time needs a wrapper that rewrites git's key argument — fragile for little gain. Moving the split to apply-time (per machine) is clean.
- **On-disk key on business**: keeps the maximum-protection posture where it matters most; business commits stay 1Password-only.

## Consequences

### Positive

- Personal commits are Verified everywhere, including headless/SSH — the original pain is gone.
- Business keeps the private key off disk.
- No wrapper script and no runtime detection; the split reuses the existing `.business_use` mechanism.
- Local verification works: `ssh-keygen -Y verify` against the rendered `allowed_signers` returns `Good "git" signature` for the on-disk key.

### Negative / accepted trade-offs

- Personal GUI sessions no longer sign through 1Password. Accepted: the on-disk key already exists and is already GitHub-trusted, so this adds no new at-rest exposure.
- The on-disk signing key has no passphrase (required for unattended headless signing); its at-rest exposure is the trade-off accepted on personal machines only.

### Required follow-up (manual, outside chezmoi)

- Register `Sl3q` as a GitHub **signing** key (it is currently an auth key only) so GitHub shows Verified for personal commits — web UI (Settings → SSH and GPG keys → New → "Signing Key") or `gh auth refresh -s admin:ssh_signing_key` then the API. `N4Wn` must likewise be registered as a signing key for business commits.

### Verification

- `chezmoi execute-template` renders the personal branch as `signingkey = ~/.ssh/id_ed25519.pub` with no `op-ssh-sign` program; the business branch mirrors it with `op-ssh-sign` + `N4Wn`.
- End-to-end local verify passes (sign with the on-disk key → verify against `allowed_signers`).
