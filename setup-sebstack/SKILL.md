---
name: setup-sebstack
description: Configure which models sebstack uses per role and at what reasoning budget. Detects your available models and writes an always-applied rule that overrides the skill defaults. Use for /setup-sebstack, "configure sebstack models", "sebstack budget", or changing sebstack's model choices.
---

# Setup sebstack

Write sebstack's model settings, one model per role:

- **Cursor:** `~/.cursor/rules/sebstack-models.mdc`, an always-applied rule.
- **Claude Code:** `~/.claude/rules/sebstack-models.md`. Claude Code loads every file in `~/.claude/rules/` into each new session.
- **Every other harness** (Codex, Pi, OpenCode, and others): `~/.agents/sebstack-models.md`. These harnesses don't load it on their own, so sebstack skills read this file when they pick a model.

"The settings file" below means the file for your harness. In Claude Code, if that file is missing, read `~/.agents/sebstack-models.md` instead, where older versions of this skill wrote it.

## Steps

### 1. Detect available models

Enumerate the model slugs you can pass to a subagent in this session (Cursor `Task`, Claude Code `Agent`, OpenCode `task`, Codex `spawn_agent`). That is the dependable source. If your harness also has a command that lists the user's models, prefer it for completeness (for example `opencode models` or `pi --list-models`). Group confirmed slugs by provider and family. Anthropic models normally use Claude, Opus, Sonnet, or Haiku names. OpenAI models normally use GPT or o-series names. If you cannot detect any, ask the user to paste the slugs they have access to. Never write a real slug you have not confirmed is available. The aliases `inherit-parent` and `auto` are always valid even though they are not detected slugs.

### 2. Load current state

The default role-to-model mapping is the rule shape shown in step 6 below. If the settings file already exists, read it and treat its `# provider`, `# budget`, and role values as the current choices. Otherwise start from those defaults. A line whose role is not in step 6, such as `how critics`, is from a retired role. Drop it.

### 3. Choose a provider profile

Use the only detected provider family when there is one. When several provider families are available, use the family of the parent chat model. Ask the user only when the parent family is unknown or when they request a mixed-provider panel.

Choose three capability tiers from that provider's confirmed models:

- **Judgment.** The strongest reasoning model. Use it for prose, synthesis, contested decisions, and the hardest code. For Anthropic this is normally the strongest available Opus model. For OpenAI prefer `gpt-6-astra` when the harness exposes it, otherwise use the strongest confirmed GPT or o-series reasoning model.
- **Workhorse.** The strongest general coding model below the judgment tier, or the judgment model when there is no separate tier. Use it for implementation, investigation, tooling, and verification. For Anthropic this is normally the strongest available Sonnet model. For OpenAI prefer `gpt-5.6-sol` when the harness exposes it, otherwise use the strongest confirmed general coding model.
- **Fast.** The fastest capable model, or the workhorse when there is no separate fast tier. Use it only for routine mechanical work. For Anthropic this is normally the strongest available Haiku model. For OpenAI prefer `gpt-5.6-luna` when the harness exposes it, then `gpt-5.6-terra`, otherwise use the fastest confirmed model.

Use judgment plus workhorse for panels. If both tiers resolve to the same slug, repeat it so the configured fan-out count stays intact. A mixed-provider panel is allowed only when every slug is confirmed in the current harness.

### 4. Budget, map, and confirm

**(a) Ask for a budget.** Prefer your structured-question tool (`AskQuestion` in Cursor, `AskUserQuestion` in Claude Code, `question` in OpenCode) over free text. Offer these four options with these exact labels, and name the current budget when the rule records one. With no rule, say that `large` matches the skill defaults.

- `unlimited — max reasoning`
- `large — xhigh reasoning`
- `medium — high reasoning`
- `small — medium reasoning`

**(b) Apply it.** Build the working table from the selected profile and the role map in step 6. On a re-run, keep any role the user changed by family, list, or alias (`inherit-parent`, `auto`). `unlimited`, `large`, `medium`, and `small` request `max`, `xhigh`, `high`, or `medium` reasoning. Use the harness's separate effort option when it has one. Change a slug only when the harness encodes effort in the slug and confirms the adjusted slug exists. Otherwise keep the confirmed slug and record the requested budget in the file. `inherit-parent` and `auto` do not change.

**(c) Show the roles and confirm.** Show every role with its model, marking any real slug not in the detected set as needing a choice. Also list each line step 2 dropped. Ask whether to accept as-is or change specific roles, offering the detected models plus `inherit-parent` and `auto` (both mean: this role runs on the parent chat model, which is how Auto users stay on Auto) as the options. Prefer your structured-question tool over free text. For panel roles (arena runners, architect runners, interrogate reviewers) the value is a list, and one subagent runs per entry, alias entries included, so the list length sets the count. `arena cross-judge pool` is also a list, but Arena runs one judge. It tries only values from a family other than the parent's, in list order, so order it by preference. An `inherit-parent` or `auto` value never judges. `swarm workers` is the default model for every worker unless a race or comparison assigns another model per arm.

### 5. Validate

Every real slug written must be in the detected set. `inherit-parent` and `auto` always pass. If a chosen real slug is not available, stop and ask again.

### 6. Write the rule

Write the settings file with a `# provider` line, a `# budget` line with the chosen label and its target effort, and one line per role. In Cursor, include the frontmatter below with `alwaysApply: true`. In other harnesses, write the settings file without the frontmatter and start at the first `#` line. Overwrite the whole file so re-runs stay idempotent. Replace `JUDGMENT`, `WORKHORSE`, and `FAST` below with confirmed slugs before writing. The tokens describe the role map and must never appear in the finished file.

```
---
description: sebstack per-role model choices (overrides skill defaults)
alwaysApply: true
---
# sebstack model configuration. One line per role. Delete a line to fall back to the skill default.
# `inherit-parent` or `auto` as a value: the role runs on the parent chat model (omit the subagent `model`). Alias entries in a panel list still count toward its fan-out.
# provider: anthropic | openai | mixed | other
# budget: large (xhigh)
feature, refactoring: WORKHORSE
bug-fix: WORKHORSE
perf-issue: WORKHORSE
hillclimb: WORKHORSE
judgment and prose: JUDGMENT
hardest tasks: JUDGMENT
how explorer: WORKHORSE
how explainer: JUDGMENT
why investigators: WORKHORSE
why synthesizer: JUDGMENT
reflect tooling: WORKHORSE
reflect judgment, divergent, synthesizer: JUDGMENT
arena runners: JUDGMENT, WORKHORSE
arena cross-judge pool: JUDGMENT, WORKHORSE
swarm workers: WORKHORSE
architect runners: JUDGMENT, WORKHORSE
interrogate reviewers: JUDGMENT, WORKHORSE
```

`FAST` is available for a user override or a task-specific downgrade. Do not assign it to a default role merely because it exists.

### 7. Confirm

Tell the user which file was written. In Cursor and Claude Code, it applies to new sessions. In other harnesses, sebstack skills read `~/.agents/sebstack-models.md` when they pick a model. Re-running this skill updates it.

### 8. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an existing harness). If not, offer once: "want a project-local verification skill, so agents can drive the app the way a user does and prove changes work? I can generate one with /create-verification-skill." On yes, invoke `/create-verification-skill` (resolves wherever sebstack is installed: workspace, user, or plugin). On no, move on without pushing.

### 9. Offer a formal verification skill (optional)

Check whether the project already has a formal verification skill (a project skill that runs a model checker, a proof, or another verifier against the code). If not, offer once: "want a formal verification skill, so agents can prove a key property of your code holds in every case in scope, not only the cases tests reach? I can generate one with /create-formal-verification-skill." On yes, invoke `/create-formal-verification-skill` (resolves wherever sebstack is installed: workspace, user, or plugin). On no, move on without pushing.
