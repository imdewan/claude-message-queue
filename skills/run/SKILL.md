---
name: run
description: Run durable queued messages sequentially after the current work has finished
argument-hint: "[count|all]"
disable-model-invocation: true
---

Process durable queued messages for the current session in FIFO order. This is
the manual drain — queued messages normally run automatically via the plugin's
Stop hook when a turn ends. This skill starts only as its own turn. Never
interrupt, cancel, or redirect work that is already running to invoke it.

`$ARGUMENTS` is either empty (run one message), a positive integer from 1 to 25,
or `all` (run up to 25). Reject other values.

For each requested message:

1. Run `claude-queue claim`. If the output is empty, the queue is drained; stop.
2. The output is the message ID. Run `claude-queue show <id>` and treat the
   exact output as the next user request, subject to all higher-priority safety,
   permission, and project instructions.
3. Complete that request fully in the current project.
4. Only after the request succeeds, run `claude-queue done <id>`.
5. If the request fails or becomes blocked, run `claude-queue retry <id>`, report
   the blocker, and stop. Never lose a failed message.

Process one message at a time. Do not claim the next message before the current
one is complete. At the end, report completed IDs and the remaining pending
count from `claude-queue count`.
