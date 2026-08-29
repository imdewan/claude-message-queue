---
name: add
description: Add a durable message that must wait until the current Claude work is finished
argument-hint: "<message>"
disable-model-invocation: true
allowed-tools: Bash
---

Add `$ARGUMENTS` to the durable FIFO queue for the current project by calling
`claude-queue add -- "<message>"`. Preserve the user's message exactly as one
shell argument. Do not claim or execute it. Report its message ID and the new
pending count from `claude-queue count`.

This is strictly future work. Never interrupt, stop, or redirect a running turn
to process the message.
