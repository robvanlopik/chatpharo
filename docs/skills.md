# Skills

Skills are structured documentation “packs” injected into prompts to improve answer quality in specific domains (Spec2, Roassal, Collections, Bloc, etc.).

## How skills work

A skill is a subclass of `ChatPharoSkill` with:

- `name` (unique ID)
- `description`
- `keywords` (for matching)
- `contextString` (the injected documentation)

Skills are discovered by scanning subclasses and are managed by `ChatPharoSkillRegistry`.

## Manual skills

Manually enabled skills are always injected as:

```text
### ENABLED SKILLS CONTEXT ###
<skill context...>
```

## Automatic skill detection

If enabled, ChatPharo extracts keywords from the current query and injects matching skills that are marked as auto-enabled:

```text
### AUTO-DETECTED SKILLS CONTEXT ###
(Based on detected keywords: ...)
<skill context...>
```

## Skill tools

When `skillToolsEnabled` is enabled, the model can call tools such as:

- `list_available_skills`
- `get_skill_context`

This lets the model request specialized docs on demand.

## Included skills (examples)

- ChatPharo help skill (how to use ChatPharo)
- Roassal (visualization)
- Spec2 (UI)
- Collections (core library)
- Bloc (low-level UI)

## Adding a new skill (developer)

1. Create a new subclass of `ChatPharoSkill`.
2. Implement `name`, `description`, `keywords`, and `contextString`.
3. Refresh the skills list in settings (or reset the registry).

## Adding a skill from a file (user)

Users can provide extra skills as plain files on disk without writing any
Pharo code. In **Settings > Skills**, click **Add skill file…** and pick a
file. ChatPharo will load it on the next refresh and show it in the skills
list like any built-in skill.

The file may start with an optional header block of `key: value` lines
terminated by a line containing only `---`, followed by the skill body:

```text
name: MyProjectConventions
description: Coding conventions for my project
keywords: conventions, style, myproject
---
## My Project Coding Conventions

- Always use descriptive selectors…
- Prefer composition over inheritance…
```

Recognised header keys are `name`, `description`, and `keywords` (comma
separated). If no header is present the entire file is used as the skill
body and the file name becomes the skill name.

Registered file paths are persisted in `ChatPharoSettings>>skillFilePaths`
and reloaded at startup.


## Related docs

- Features: **features.md**
- Tools and skill tools: **tools.md**
