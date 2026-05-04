---
name: codewiki-tasks
description: Generate implementation tasks from a PRD
argument-hint: <prd-file-path>
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task]
---

# CodeWiki Tasks

<purpose>
Convert a PRD into an implementation task list that reflects both the requested behavior and the
current codebase. Default to the two-phase parent-task then sub-task interaction model, with
`--fast` available for one-pass generation when the user explicitly asks for speed.
</purpose>

<process>
## Step 1: Resolve the task directory
- Read `.codewiki/config.yml` if it exists.
- Use `wiki.tasks_path` as the PRD/task directory when present.
- If `wiki.tasks_path` is missing, use `.codewiki/tasks/`.

## Step 2: Resolve the PRD
- Treat `$ARGUMENTS` as the PRD path.
- Ignore mode flags such as `--fast` when resolving the path.
- If the path is relative and does not exist, also try resolving it under the task directory.
- If no path was provided, search the task directory for `*-prd-*.md`.
- If exactly one PRD exists, use it.
- If multiple PRDs exist, prefer the most recently modified PRD and tell the user which one you chose. If that choice is ambiguous or risky, ask the user which PRD file to use.
- Read the PRD in full before generating tasks.

## Step 3: Choose the interaction mode
- If `$ARGUMENTS` contains `--fast`, switch to fast mode.
- Otherwise default to interactive mode.

## Step 4: Analyze the current codebase with subagents
- Use `Task` for a two-agent split:
  1. an analyze agent reads the PRD, project config, and existing feature patterns
  2. a generate agent turns that analysis into the task breakdown
- Reuse existing modules and utilities whenever possible instead of duplicating work.

## Step 5: Generate parent tasks
- Produce the main high-level tasks first.
- Base them on the PRD, existing architecture, reusable code, and likely test coverage needs.
- Keep the task count practical and implementation-oriented.

## Step 6: Preserve the interactive gate
- In interactive mode, stop after the parent tasks and tell the user:
  "I have generated the high-level tasks based on the PRD. Ready to generate the sub-tasks?
  Respond with 'Go' to proceed."
- Wait for "Go" before expanding the task list.
- In fast mode, skip the pause and generate parent tasks plus sub-tasks in one pass.

## Step 7: Generate sub-tasks and relevant files
- Break each parent task into smaller actionable sub-tasks.
- Add a `Relevant Files` section with expected implementation and test files.
- Note reusable utilities, patterns, and constraints that matter to execution.

## Step 8: Save the task list
- Save the file to `[task-directory]/tasks-[prd-file-name].md`.
- Keep the output in Markdown and preserve task numbering.

## Step 9: Boundaries
- Do not create commits automatically; the user controls git operations.
- Keep the final task list aligned to the PRD instead of speculative stretch work.
</process>
