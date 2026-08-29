---
name: add
description: Add a durable message that runs automatically once the current Claude work is finished
argument-hint: "<message>"
disable-model-invocation: true
allowed-tools: Bash
---

Add `$ARGUMENTS` to the durable FIFO queue for the current session by calling
`claude-queue add -- "<message>"`. Preserve the user's message exactly as one
shell argument. Do not claim or execute it inside this skill. Report its
message ID and the new pending count from `claude-queue count`, and tell the
user it will run automatically as soon as the current work finishes — the
plugin's Stop hook picks it up the moment the turn ends, so if nothing else is
running it starts right away.

Never interrupt, stop, or redirect a running turn to process the message; the
Stop hook handles execution after the turn completes.
