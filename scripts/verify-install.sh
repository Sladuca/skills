#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
skill_list="$repo_root/personal-skills.txt"
targets=("$HOME/.claude/skills" "$HOME/.codex/skills")
count=0

while IFS= read -r skill; do
  [[ -n "$skill" ]] || continue
  source_path="$repo_root/$skill"
  [[ -f "$source_path/SKILL.md" ]] || {
    echo "Missing canonical skill $source_path/SKILL.md" >&2
    exit 1
  }

  for target_root in "${targets[@]}"; do
    target_path="$target_root/$skill"
    [[ -L "$target_path" ]] || {
      echo "Expected a symbolic link at $target_path" >&2
      exit 1
    }
    [[ -e "$target_path" ]] || {
      echo "Broken symbolic link at $target_path" >&2
      exit 1
    }
    [[ "$(readlink -f "$target_path")" == "$source_path" ]] || {
      echo "Wrong link target at $target_path" >&2
      exit 1
    }
    [[ -f "$target_path/SKILL.md" ]] || {
      echo "Skill is not discoverable at $target_path" >&2
      exit 1
    }
  done
  count=$((count + 1))
done < "$skill_list"

echo "Verified $count canonical skills in ${#targets[@]} discovery roots."
