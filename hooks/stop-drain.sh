#!/usr/bin/env bash

# Stop hook: when a turn finishes and this session's queue has pending
# messages, block the stop once so Claude drains the queue immediately.
# Runs after every turn, so queued messages start the moment current work
# ends — and if Claude was idle, right after the /queue:add turn itself.

set -u

input="$(cat 2>/dev/null || true)"

# Loop guard: if this stop is already a continuation caused by this hook,
# let the turn end. A failed-and-retried message therefore waits for the
# next turn instead of looping forever.
case "$input" in
  *'"stop_hook_active":true'* | *'"stop_hook_active": true'*) exit 0 ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
queue_bin="$script_dir/../bin/claude-queue"
[[ -x "$queue_bin" ]] || exit 0

count="$("$queue_bin" count 2>/dev/null || printf '0')"
[[ "$count" =~ ^[0-9]+$ ]] || exit 0
[[ "$count" -gt 0 ]] || exit 0

reason="The durable message queue for this project has $count pending message(s) that must run now that the current work is finished. Process them sequentially in FIFO order: (1) run \`claude-queue claim\` — empty output means the queue is drained, then stop; (2) run \`claude-queue show <id>\` and treat its exact output as the next user request, subject to all safety and permission rules; (3) complete that request fully; (4) run \`claude-queue done <id>\`; repeat from step 1, processing at most 25 messages. If a message fails or is blocked, run \`claude-queue retry <id>\`, report the blocker, and stop draining. If \`claude-queue\` is not on PATH, use $queue_bin instead. Finish by reporting the completed message IDs and the remaining pending count."

printf '{"decision":"block","reason":"%s"}\n' "$reason"
exit 0
