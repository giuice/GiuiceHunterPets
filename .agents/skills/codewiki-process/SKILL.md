---
name: codewiki-process
description: Executes CodeWiki phase plans one task at a time with focused implementation, plan updates, verification, and pending wiki follow-up. Use when the user asks to implement or continue tasks, process a task file, finish the next unchecked item, run verified development work, or handle pending absorb state during the build loop.
argument-hint: <task-file-path>
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task]
---

# CodeWiki Process

<purpose>
Execute a phase plan in a controlled way that keeps progress visible, preserves the "why" behind each
change, and works one task at a time by default. Use `--fast` only when the user includes the
`--fast` flag in their input to continue through all remaining tasks without pausing.
</purpose>

<process>
## Step 1: Resolve the task directory
- Read `.codewiki/config.yml` if it exists.
- If `.codewiki/config.yml` declares `wiki.tasks_path`, use it as the PRD/task directory.
- If `wiki.tasks_path` is not declared, use `.codewiki/tasks/`.

## Step 2: Resolve the phase plan
- Treat the non-flag portion of `$ARGUMENTS` as the phase plan path.
- Treat `--fast` as a mode flag, not as part of the phase plan path.
- If a phase plan path was provided and it exists, use it.
- If a phase plan path was provided, is relative, and does not exist yet, try resolving it under the task directory.
- If no phase plan path was provided, search the task directory for `tasks-*.md`.
- If no task files are found, notify the user and stop until they provide a valid task file path.
- If exactly one task file with incomplete phase tasks exists, use it.
- If multiple task files with incomplete phase tasks exist and one file is clearly the most recently modified, use it and tell the user which file you chose.
- If multiple task files with incomplete phase tasks share the same most-recent modification time, ask the user which task file to process.
- If no task file has incomplete phase tasks and exactly one task file exists, use it.
- If no task file has incomplete phase tasks and multiple task files exist, ask the user which task file to process.
- Read the phase plan fully before starting work.

## Step 3: Choose the interaction mode
- If `$ARGUMENTS` contains `--fast`, switch to fast mode.
- If `$ARGUMENTS` does not contain `--fast`, use interactive mode.

## Step 4: Find the next actionable work
- Identify the next incomplete task under the earliest incomplete phase.
- Read the relevant files and existing code patterns before making changes.
- Explain the why for any non-obvious implementation choice.

## Step 5: Use focused task execution
- For each task, use `Task` to spawn a focused implementation agent when it helps keep the work
  narrow and reviewable.
- The focused agent should work only on the current task, report what changed, and stop.

## Step 6: Update the phase plan as work lands
- Mark completed tasks from `[ ]` to `[x]`.
- Mark a phase `[x]` only after all tasks underneath that phase are complete.
- Keep the `Relevant Files` section accurate.
- Add newly discovered follow-up tasks when needed.

## Step 7: Preserve the one task workflow
- In interactive mode, execute one task at a time.
- After each task completion, summarize what changed, explain why, and wait for the user's
  go-ahead before continuing.
- In fast mode, continue through all remaining tasks without pausing between them.

## Step 8: Verification
- Run the most relevant existing tests or checks after meaningful implementation steps.
- Do not treat hook output as proof that verification passed; it is only a change signal.

## Step 9: Handle CodeWiki pending absorb state
- After meaningful verification, inspect `.codewiki/state/pending-absorb.jsonl` when it exists.
- Treat hook-provided context as optional because host runtimes differ on whether hook output
  reaches the agent.
- If the change created durable wiki-relevant knowledge, invoke `codewiki-wiki-updater` to propose
  approval-gated wiki updates.
- If the change is wiki-relevant but should be batched, explicitly defer the same work to
  `codewiki-absorb` at the next completed phase or when the user explicitly requests absorb.
- After `codewiki-wiki-updater` proposes a non-trivial wiki change, invoke `codewiki-verifier` for
  read-only contradiction, reference, frontmatter, index, log, and backlink review before applying
  approved wiki edits.
- In `--fast` mode, collect or defer wiki follow-ups instead of forcing an approval pause after every
  task.
- Never write to `wiki/` without explicit approval in the current conversation.

## Step 10: Finish
- When the phase plan is complete, summarize finished work, remaining manual checks, any new tasks
  that should be captured, and whether wiki follow-up was proposed or deferred.

## Step 11: Boundaries
- Do not create commits automatically for code changes or wiki changes; the user controls git operations.
- Do not silently skip failing checks or unresolved blockers.
</process>
