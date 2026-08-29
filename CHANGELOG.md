# Changelog

## 0.2.0 - 2026-08-29

- Run queued messages automatically: a `Stop` hook drains the queue the moment
  the current turn finishes, so `/queue:add` no longer waits for a manual
  `/queue:run`. If Claude is idle, the message runs immediately.
- Scope queues per Claude session (CLI and Desktop), so other sessions on the
  same project never pick up another session's messages. Messages added from a
  plain terminal go to a shared project queue that any session drains as a
  fallback after its own.
- Add `--shared` and `CLAUDE_QUEUE_SESSION` to control scoping explicitly.
- Keep message IDs monotonic across session and shared queues so FIFO order
  holds project-wide.
- Add session-scoping and Stop-hook tests.

## 0.1.1 - 2026-08-29

- Recover automatically when a killed queue writer leaves a stale PID lock.

## 0.1.0 - 2026-08-29

- Add a non-interrupting durable FIFO queue for future Claude turns.
- Add the `/queue:add`, `/queue:list`, `/queue:run`, and `/queue:manage` command family.
- Add the standalone `claude-queue` command.
- Share queues across Git worktrees on the same machine.
- Add lifecycle, ordering, concurrency, and cross-worktree tests.
