---
name: list
description: Inspect durable queued messages without running or removing them
argument-hint: "[peek|<id>]"
disable-model-invocation: true
allowed-tools: Bash
---

Inspect the durable queue for the current project without claiming, executing,
removing, or changing any message.

- With no arguments, call `claude-queue list` and reproduce the result.
- With `peek`, call `claude-queue peek` and show the next message.
- With a message ID, call `claude-queue show <id>` and show that message.
- Reject any other form and show these supported forms.
