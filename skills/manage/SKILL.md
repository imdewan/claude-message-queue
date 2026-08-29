---
name: manage
description: Retry, remove, clear, or diagnose the durable message queue
argument-hint: "retry <id> | remove <id> | clear | doctor"
disable-model-invocation: true
allowed-tools: Bash
---

Manage the durable queue for the current project without executing messages.

- `retry <id>`: call `claude-queue retry <id>`.
- `remove <id>`: call `claude-queue remove <id>`.
- `clear`: ask for confirmation. Only after confirmation call
  `claude-queue clear --yes`.
- `doctor`: call `claude-queue doctor`.

Reject any other operation and show these supported forms. Never interrupt or
redirect current work and never claim a message in this skill.
