#!/usr/bin/env bash
# ~/.agents/install.sh — single point of reference for all AI agents.
#
# Canonical state lives HERE in ~/.agents (or wherever this repo is cloned):
#   AGENTS.md      -> global instructions (edit only here)
#   skills/<name>/ -> canonical skills (each has SKILL.md)
#
# The script symlinks every consumer to the canonical files:
#   files: ~/AGENTS.md, ~/.codex/AGENTS.md, ~/.claude/CLAUDE.md,
#          ~/.config/opencode/AGENTS.md
#   skills dirs: ~/.claude/skills, ~/.codex/skills, ~/.pi/agent/skills,
#          ~/.config/opencode/skills (~/.copilot/skills if present)
#
# New device usage:
#   git clone <your-agents-repo-url> ~/.agents
#   ~/.agents/install.sh
#
# Safe to re-run: backs up anything it replaces into
# ~/.agents/skill-backups/<timestamp>/ and never deletes skills.
set -euo pipefail

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=1 ;;
    -h|--help)
      echo "Usage: install.sh [--dry-run]"
      echo "Links all agent configs to this repo's AGENTS.md + skills/."
      exit 0 ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CANON="$REPO_DIR/AGENTS.md"
SKILLS="$REPO_DIR/skills"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$REPO_DIR/skill-backups/$STAMP"

log()  { printf '  %-9s %s\n' "$1" "$2"; }
run()  { if [ "$DRY_RUN" = 1 ]; then echo "  [dry-run] $*"; else "$@"; fi; }
backup() { # backup <path>
  if [ -e "$1" ] && [ ! -L "$1" ]; then
    run mkdir -p "$BACKUP_DIR"
    run mv "$1" "$BACKUP_DIR/$(echo "$1" | tr '/' '_').bak"
    log "backup" "$1 -> $BACKUP_DIR/"
  fi
}

link_file() { # link_file <canonical-src> <dest>
  local src="$1" dest="$2"
  [ -e "$src" ] || { log "SKIP" "$src missing, not linking $dest"; return 0; }
  if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
    log "ok" "$dest already -> $src"; return 0
  fi
  backup "$dest"
  run mkdir -p "$(dirname "$dest")"
  run ln -sfn "$src" "$dest"
  log "link" "$dest -> $src"
}

adopt_skill() { # adopt_skill <name> — pull real dir from a consumer into canonical
  local name="$1" consumer src
  [ -e "$SKILLS/$name" ] && return 0
  for consumer in "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.config/opencode/skills" "$HOME/.pi/agent/skills"; do
    src="$consumer/$name"
    if [ -d "$src" ] && [ ! -L "$src" ]; then
      log "adopt" "$src -> $SKILLS/$name"
      if [ "$DRY_RUN" = 0 ]; then
        mv "$src" "$SKILLS/$name"
        ln -sfn "$SKILLS/$name" "$src"
      fi
      return 0
    fi
  done
}

link_skill() { # link_skill <name> <consumer-skills-dir>
  local name="$1" dir="$2" dest="$dir/$name" src="$SKILLS/$name"
  [ -e "$src" ] || [ -L "$src" ] || { log "SKIP" "no canonical skill $name"; return 0; }
  # Never clobber Codex's built-in .system dir or machine-synced bulk dir blindly.
  if [ -L "$dest" ] && [ "$(readlink -f "$dest" 2>/dev/null || true)" = "$(readlink -f "$src" 2>/dev/null || true)" ]; then
    log "ok" "$dest already linked"; return 0
  fi
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    # Consumer has its own real copy: if canonical is identical, replace with link;
    # otherwise adopt-rename so nothing is lost.
    if diff -rq "$src" "$dest" >/dev/null 2>&1; then
      backup "$dest"; run rm -rf "$dest"
    else
      log "DIVERGE" "$dest differs from canonical, backing up not overwriting"
      backup "$dest"; run rm -rf "$dest"
    fi
  fi
  run mkdir -p "$dir"
  run ln -sfn "$src" "$dest"
  log "link" "$dest -> $src"
}

echo "== 1/3 global instructions =="
link_file "$CANON" "$HOME/AGENTS.md"
link_file "$CANON" "$HOME/.codex/AGENTS.md"
link_file "$CANON" "$HOME/.claude/CLAUDE.md"
link_file "$CANON" "$HOME/.config/opencode/AGENTS.md"

echo "== 2/3 adopt stray skills into canonical + prune dead links =="
for sdir in "$HOME/.claude/skills" "$HOME/.config/opencode/skills" "$HOME/.codex/skills"; do
  [ -d "$sdir" ] || continue
  for d in "$sdir"/*/ "$sdir"/.*; do
    [ -L "$d" ] || continue
    # prune broken symlinks (e.g. find-skills whose canonical was deleted)
    if [ ! -e "$d" ]; then
      log "prune" "dead link $d (target $(readlink "$d") missing)"
      [ "$DRY_RUN" = 0 ] && rm -f "$d"
    fi
  done
  for d in "$sdir"/*/; do
    [ -d "$d" ] || continue
    n="$(basename "$d")"
    [ "$n" = "synced" ] && continue
    adopt_skill "$n"
  done
done

echo "== 3/3 link skills to every consumer =="
CONSUMERS=("$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.pi/agent/skills" "$HOME/.config/opencode/skills")
[ -d "$HOME/.copilot" ] && CONSUMERS+=("$HOME/.copilot/skills")
for skill_path in "$SKILLS"/*/; do
  [ -d "$skill_path" ] || continue
  name="$(basename "$skill_path")"
  # synced/ and .trash are machine-local bulk dirs: link whole dir, don't expand.
  if [ "$name" = "synced" ] || [ "$name" = ".trash" ]; then
    for dir in "${CONSUMERS[@]}"; do
      [ "$dir" = "$HOME/.codex/skills" ] && continue  # codex syncs itself
      if [ ! -e "$dir/$name" ] && [ ! -L "$dir/$name" ]; then
        run mkdir -p "$dir"; run ln -sfn "$skill_path" "$dir/$name"
        log "link" "$dir/$name -> $skill_path (bulk)"
      fi
    done
    continue
  fi
  for dir in "${CONSUMERS[@]}"; do
    # pi/codex may not be installed on a fresh box — still create the dir, harmless.
    link_skill "$name" "$dir"
  done
done

echo
echo "Done. Canonical: $CANON + $SKILLS/"
echo "Backups (if any): $BACKUP_DIR/"
[ "$DRY_RUN" = 1 ] && echo "(dry-run: nothing was changed)"
echo "Verify: ls -la ~/AGENTS.md ~/.codex/AGENTS.md ~/.claude/CLAUDE.md && ls -la ~/.claude/skills ~/.codex/skills ~/.pi/agent/skills"
