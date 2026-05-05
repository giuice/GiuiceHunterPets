---
name: codewiki-prd
description: Drafts an implementation-ready Product Requirements Document from a feature idea using repository and wiki context. Use when the user wants to plan a new feature, clarify product intent, define scope before implementation, capture acceptance criteria, or start the CodeWiki PRD -> tasks -> process development workflow.
argument-hint: <feature-description>
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task]
---

# CodeWiki PRD

<purpose>
Turn a feature idea into a concrete Product Requirements Document that fits the current codebase.
Use the existing repository and wiki as context. Default to an interactive clarification flow unless
the user includes the `--fast` flag in their input to request one-pass drafting.
</purpose>

<process>
## Step 1: Capture the request
- Treat `$ARGUMENTS` as the feature description.
- If the feature description is missing, ask the user to describe the feature first.

## Step 2: Resolve the task directory
- Read `.codewiki/config.yml` if it exists.
- If `.codewiki/config.yml` declares `wiki.tasks_path`, use it as the PRD/task directory.
- If `wiki.tasks_path` is not declared, use `.codewiki/tasks/`.
- Create the directory if it does not exist.

## Step 3: Choose the interaction mode
- If `$ARGUMENTS` contains `--fast`, switch to fast mode.
- If `$ARGUMENTS` does not contain `--fast`, use interactive mode.
- In interactive mode, ask clarifying questions before writing the PRD. Use lettered or numbered
  options so the user can answer quickly.

## Step 4: Research current state with subagents
- Use `Task` to spawn parallel research agents:
  1. one agent reads architecture, schema, and project docs
  2. one agent searches the codebase for related features, patterns, and reusable modules
- Synthesize their findings before drafting the PRD.

## Step 5: Ask clarifying questions in interactive mode
- Focus on the what and why:
  - problem or goal
  - target user
  - core functionality
  - user stories
  - acceptance criteria
  - scope boundaries
  - data requirements
  - design considerations
  - edge cases
- In fast mode, skip the clarifying questions and make reasonable assumptions explicit in the PRD.

## Step 6: Draft the PRD
- Use this structure:
  1. Introduction / Overview
  2. Goals
  3. User Stories
  4. Functional Requirements
  5. Non-Goals
  6. Design Considerations
  7. Technical Considerations
  8. Success Metrics
  9. Open Questions
- Keep requirements explicit, unambiguous, and implementation-ready without junior-developer framing.

## Step 7: Save the PRD
- Save the document as `[task-directory]/[n]-prd-[feature-name].md`.
- Use a zero-padded 4-digit sequence such as `0001-prd-example-feature.md`.
- If a filename collision exists, increment the sequence rather than overwriting.

## Step 8: Boundaries
- Do not start implementing the feature from this command.
- Do not create commits automatically; the user controls git operations.
</process>
