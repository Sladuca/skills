#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
skill_list="$repo_root/personal-skills.txt"
targets=("$HOME/.claude/skills" "$HOME/.codex/skills")

while IFS= read -r skill; do
  [[ -n "$skill" ]] || continue
  source_path="$repo_root/$skill"
  [[ -f "$source_path/SKILL.md" ]] || {
    echo "Missing $source_path/SKILL.md" >&2
    exit 1
  }

  for target_root in "${targets[@]}"; do
    mkdir -p "$target_root"
    target_path="$target_root/$skill"

    if [[ -L "$target_path" ]]; then
      current=$(readlink -f "$target_path" || true)
      if [[ "$current" == "$source_path" ]]; then
        continue
      fi
      echo "Refusing to replace link $target_path -> $(readlink "$target_path")" >&2
      exit 1
    fi

    if [[ -e "$target_path" ]]; then
      echo "Refusing to replace existing path $target_path" >&2
      exit 1
    fi

    ln -s "$source_path" "$target_path"
  done
done < "$skill_list"

"$repo_root/scripts/verify-install.sh"
