# agents — single source of truth for all my AI agents

Canonical global instructions + skills. Every agent on every machine
symlinks to these files; **edit only here**.

## Layout

```
AGENTS.md      # global instructions (git identity, Rails rules, ...)
install.sh     # idempotent installer — symlinks everything into place
skills/        # canonical skills, one dir per skill (each has SKILL.md)
```

## Install (new device)

```bash
git clone https://github.com/yesheytenzin/agents.git ~/.agents
~/.agents/install.sh --dry-run   # preview
~/.agents/install.sh             # link everything
```

What it links:

- `~/AGENTS.md`, `~/.codex/AGENTS.md`, `~/.claude/CLAUDE.md`,
  `~/.config/opencode/AGENTS.md` → `AGENTS.md`
- every skill into `~/.claude/skills/`, `~/.codex/skills/`,
  `~/.pi/agent/skills/`, `~/.config/opencode/skills/`
  (and `~/.copilot/skills/` if Copilot exists)

Safe to re-run. Anything it replaces is backed up into
`~/.agents/skill-backups/<timestamp>/`.

## Add / edit

- Edit `AGENTS.md` or `skills/<name>/`, commit, push, pull on other machines,
  re-run `install.sh`.
- Upstream-backed skills (`omarchy*`, `diagnose-crash`, `superwhisper`) are
  vendored as real dirs here so fresh machines work without the upstream
  installed. Refresh them with `cp -r <upstream> skills/<name>` when upstream
  changes.
- `skills/synced/` (machine auto-sync) is deliberately not committed.
