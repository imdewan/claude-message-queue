# Changelog

## 0.1.1 - 2026-08-29

- Recover automatically when a killed queue writer leaves a stale PID lock.

## 0.1.0 - 2026-08-29

- Add a non-interrupting durable FIFO queue for future Claude turns.
- Add the `/queue:add`, `/queue:list`, `/queue:run`, and `/queue:manage` command family.
- Add the standalone `claude-queue` command.
- Share queues across Git worktrees on the same machine.
- Add lifecycle, ordering, concurrency, and cross-worktree tests.
