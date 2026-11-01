#!/usr/bin/env bash
# Install Semantic Model Dashboard Skills into an AI agent's skills folder.
#
# Usage:
#   ./scripts/install.sh --agent <claude|codex|antigravity|kiro|agents> [options]
#   ./scripts/install.sh --dest <folder> [options]
#
# Options:
#   --agent NAME     Target agent (see table below).
#   --scope SCOPE    user (default) = available in every project; project = only in --target.
#   --target DIR     Project root for --scope project (default: current directory).
#   --dest DIR       Install into an explicit skills folder instead of an agent default.
#   --link           Symlink skills instead of copying (git pull then updates them).
#   --skills LIST    Comma-separated skill names to install (default: all).
#   --force          Replace skills that already exist at the destination.
#   --dry-run        Show what would happen without changing anything.
#   -h, --help       Show this help.
#
# Default destinations:
#   agent        user scope                      project scope
#   claude       ~/.claude/skills                <target>/.claude/skills
#   codex        ~/.agents/skills                <target>/.agents/skills
#   antigravity  ~/.gemini/config/skills         <target>/.agents/skills
#   kiro         ~/.kiro/skills                  <target>/.kiro/skills
#   agents       ~/.agents/skills                <target>/.agents/skills   (generic open-standard folder)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_ROOT/skills"

AGENT=""
SCOPE="user"
TARGET="$(pwd)"
DEST=""
LINK=0
SKILLS=""
FORCE=0
DRY=0

usage() { sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)   AGENT="${2:-}"; shift 2 ;;
    --scope)   SCOPE="${2:-}"; shift 2 ;;
    --target)  TARGET="${2:-}"; shift 2 ;;
    --dest)    DEST="${2:-}"; shift 2 ;;
    --link)    LINK=1; shift ;;
    --skills)  SKILLS="${2:-}"; shift 2 ;;
    --force)   FORCE=1; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$DEST" ]]; then
  if [[ -z "$AGENT" ]]; then
    echo "Specify --agent or --dest." >&2; usage; exit 2
  fi
  case "$SCOPE" in user|project) ;; *) echo "--scope must be user or project" >&2; exit 2 ;; esac
  case "$AGENT:$SCOPE" in
    claude:user)          DEST="$HOME/.claude/skills" ;;
    claude:project)       DEST="$TARGET/.claude/skills" ;;
    codex:user)           DEST="$HOME/.agents/skills" ;;
    codex:project)        DEST="$TARGET/.agents/skills" ;;
    antigravity:user)     DEST="$HOME/.gemini/config/skills" ;;
    antigravity:project)  DEST="$TARGET/.agents/skills" ;;
    kiro:user)            DEST="$HOME/.kiro/skills" ;;
    kiro:project)         DEST="$TARGET/.kiro/skills" ;;
    agents:user)          DEST="$HOME/.agents/skills" ;;
    agents:project)       DEST="$TARGET/.agents/skills" ;;
    *) echo "Unknown agent: $AGENT (use claude, codex, antigravity, kiro, agents or --dest)" >&2; exit 2 ;;
  esac
fi

# Collect skills to install.
declare -a NAMES=()
if [[ -n "$SKILLS" ]]; then
  IFS=',' read -r -a NAMES <<< "$SKILLS"
else
  for d in "$SRC"/*/; do
    [[ -f "$d/SKILL.md" ]] && NAMES+=("$(basename "$d")")
  done
fi

echo "Installing ${#NAMES[@]} skill(s) into: $DEST"
[[ $LINK -eq 1 ]] && echo "Mode: symlink" || echo "Mode: copy"
[[ $DRY -eq 1 ]] && echo "(dry run — no changes)"

run() { if [[ $DRY -eq 1 ]]; then echo "  + $*"; else "$@"; fi; }

run mkdir -p "$DEST"

installed=0; skipped=0
for name in "${NAMES[@]}"; do
  name="$(echo "$name" | xargs)"
  src="$SRC/$name"
  dst="$DEST/$name"
  if [[ ! -f "$src/SKILL.md" ]]; then
    echo "  ! $name: not found in $SRC" >&2; exit 1
  fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    if [[ $FORCE -eq 1 ]]; then
      run rm -rf "$dst"
    else
      echo "  - $name: already exists (use --force to replace)"; skipped=$((skipped+1)); continue
    fi
  fi
  if [[ $LINK -eq 1 ]]; then
    run ln -s "$src" "$dst"
  else
    run cp -R "$src" "$dst"
  fi
  echo "  ✓ $name"
  installed=$((installed+1))
done

echo
echo "Done: $installed installed, $skipped skipped."
echo "Restart or reload your agent so it discovers the new skills."
