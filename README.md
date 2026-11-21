# Personal agent skills

This repository is the canonical copy of personal skills shared by Claude Code and OpenAI Codex.

Each skill is a top-level directory with a `SKILL.md` file. Supporting scripts, references, playbooks, and assets stay inside the same directory.

## Install the links

Run the installer from this checkout.

```bash
./scripts/install-links.sh
```

The installer links each skill into both `~/.claude/skills` and `~/.codex/skills`. It does not replace real directories or files. Move an existing conflicting path to a backup before rerunning the installer.

## Verify the installation

```bash
./scripts/verify-install.sh
```

The check fails if a listed skill is missing, a link is broken, a link points outside this checkout, or a skill lacks `SKILL.md`.

System, plugin-managed, synced, and project-local skills stay in their original locations. The installer does not change those directories.
