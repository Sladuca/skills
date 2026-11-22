# Personal agent skills

This repository is the canonical copy of personal skills shared by Claude Code and OpenAI Codex.

## Attribution

These skills began as a fork of [pstack](https://github.com/cursor/plugins/tree/main/pstack) by Lauren Tan ([poteto](https://x.com/poteto)), from the [cursor/plugins](https://github.com/cursor/plugins) repository. Most skills keep pstack's names and have been edited since. Three were renamed:

| pstack | this repository |
| --- | --- |
| `poteto-mode` | `sebmode` |
| `poteto-help` | `sebhelp` |
| `setup-pstack` | `setup-sebstack` |

`ship` is not from pstack. pstack is released under the MIT License, and its copyright notice and license text are in [LICENSE](./LICENSE).

## Layout

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
