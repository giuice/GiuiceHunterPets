---
name: codewiki-process
description: Execute tasks from a task list one sub-task at a time
argument-hint: <task-file-path>
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task]
---

# CodeWiki Process

<purpose>
Execute a task list in a controlled way that keeps progress visible, preserves the "why" behind each
change, and works one sub-task at a time by default. Use `--fast` only when the user explicitly
asks to continue through all remaining sub-tasks without pausing.
</purpose>

<process>
## Step 1: Resolve the task directory
- Read `.codewiki/config.yml` if it exists.
- Use `wiki.tasks_path` as the PRD/task directory when present.
- If `wiki.tasks_path` is missing, use `.codewiki/tasks/`.

## Step 2: Resolve the task list
- Treat `$ARGUMENTS` as the task list path.
- Ignore mode flags such as `--fast` when resolving the path.
- If the path is relative and does not exist, also try resolving it under the task directory.
- If the path is missing, search the task directory for `tasks-*.md`.
- Prefer a task list with incomplete `- [ ]` sub-tasks. If there is exactly one such file, use it.
- If multiple task lists have incomplete sub-tasks, prefer the most recently modified one and tell the user which one you chose. If that choice is ambiguous or risky, ask the user which task file to process.
- Read the task file fully before starting work.

## Step 3: Choose the interaction mode
- If `$ARGUMENTS` contains `--fast`, switch to fast mode.
- Otherwise default to interactive mode.

## Step 4: Find the next actionable work
- Identify the next incomplete sub-task in the list.
- Read the relevant files and existing code patterns before making changes.
- Explain the why for any non-obvious implementation choice.

## Step 5: Use focused subtask execution
- For each sub-task, use `Task` to spawn a focused subtask executor when it helps keep the work
  narrow and reviewable.
- The subtask executor should work only on the current sub-task, report what changed, and stop.

## Step 6: Update the task list as work lands
- Mark completed sub-tasks from `[ ]` to `[x]`.
- Keep the `Relevant Files` section accurate.
- Add newly discovered follow-up tasks when needed.

## Step 7: Preserve the one sub-task workflow
- In interactive mode, execute one sub-task at a time.
- After each one sub-task completion, summarize what changed, explain why, and wait for the user's
  go-ahead before continuing.
- In fast mode, continue through all remaining sub-tasks without pausing between them.

## Step 8: Verification and finish
- Run the most relevant existing tests or checks after meaningful implementation steps.
- When the task list is complete, summarize finished work, remaining manual checks, and any new
  tasks that should be captured.

## Step 9: Boundaries
- Do not create commits automatically; the user controls git operations.
- Do not silently skip failing checks or unresolved blockers.
</process>
