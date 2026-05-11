---
name: plan-first
description: Use this skill whenever a complex coding task is requested. It forces a planning phase and a TODO.md checklist before any code is modified.
---

# Plan-First Skill

## Rules
- Before using `write` or `edit` tools, you MUST create a `TODO.md` file in the project root.
- Analyze the project structure (`ls -R`) and existing dependencies first.
- Clearly define the architectural changes in the `TODO.md`.
- Ask for user approval (type "READY?") before executing the first task.
- Check off completed tasks in `TODO.md` as you progress.
