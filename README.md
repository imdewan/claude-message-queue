# Claude Message Queue

A durable, non-interrupting next-turn queue for Claude Code CLI and the Code tab
in Claude Desktop.

Claude already has a native in-flight queue: while it is working, type another
message and press Enter. The current turn keeps running, and the new message is
processed afterward. This project does **not** interrupt or inject instructions
into that turn.

The plugin adds the missing durable layer: save a backlog, inspect it, and run
messages in FIFO order across restarts and across CLI/Desktop sessions on the
same machine.

## What works where

| Capability | Claude Code CLI | Claude Desktop Code tab |
| --- | --- | --- |
| Send while busy, run after the current turn | Native | Native |
| `/queue:*` command family | Yes | Yes, in local and SSH Code sessions |
| Durable queue across restarts | Yes | Yes |
| Shared queue across local Git worktrees | Yes | Yes |
| Standalone `claude-queue` shell command | Yes | Yes, from the integrated terminal after CLI install |

Claude Desktop's Code tab and the CLI use the same underlying Claude Code
engine and share configuration, plugins, skills, and `CLAUDE.md`. Their session
histories stay separate. The ordinary Claude Desktop chat surface is a different
product surface and does not load Claude Code plugins.

## Requirements

- Claude Code 2.1.206 or newer is recommended. That release fixed a Desktop
  mid-turn command delivery issue; use the newest stable version available.
- macOS or Linux for the standalone Bash command. Claude Code's plugin skills
  also work in supported local/SSH Desktop Code sessions.
- `git` is optional. In a Git repository, all local worktrees share one queue.

## Install the extension

Add this repository as a Claude plugin marketplace, then install the plugin:

```text
/plugin marketplace add imdewan/claude-message-queue
/plugin install queue@imdewan-claude-tools
```

Claude requires marketplace-plugin skills to use a namespace. Naming the plugin
`queue` gives the short `/queue:add`, `/queue:list`, `/queue:run`, and
`/queue:manage` family. A bare global `/queue` would require a separate personal
skill, which this project deliberately does not install.

Run those in Claude Code CLI, or use **+ → Plugins → Add plugin** in the
Desktop Code tab. Install at user scope to make it available in every project.
If prompted, run `/reload-plugins` or start a new session.

For local development without installing:

```sh
git clone https://github.com/imdewan/claude-message-queue.git
claude --plugin-dir ./claude-message-queue
```

## Use the native next-turn queue

This is the Codex-like behavior for messages sent during active work:

1. Start a task and let Claude work.
2. Type the next message while the turn is still running.
3. Press Enter. Do **not** press Escape.
4. Claude finishes the current turn, then starts the queued message.

No slash command is needed for temporary in-flight messages.

## Use the durable queue

Add work for later:

```text
/queue:add Run the full test suite and fix any failures
```

Inspect it without executing anything:

```text
/queue:list
/queue:list peek
```

Run the next item as a new turn after current work has finished:

```text
/queue:run
```

Run a bounded batch sequentially:

```text
/queue:run 3
/queue:run all
```

The runner claims only one item at a time. It marks an item complete only after
the task succeeds. A failed or blocked item is returned to the queue.

To install only the shell command without `/queue`:

```sh
./scripts/install-cli.sh
```

This installs `claude-queue` to `~/.local/bin` by default. Override that with
`CLAUDE_QUEUE_INSTALL_DIR`.

Examples:

```sh
claude-queue add "Review the auth changes after the current task"
claude-queue list
claude-queue peek
id="$(claude-queue claim)"
claude-queue show "$id"
claude-queue done "$id"
```

Use the Desktop integrated terminal to add a durable item while Claude is busy;
the active turn is not interrupted. Run `/queue:run` later to execute it.

## Queue model

- **Scope:** the local Git common directory. Main checkout and worktrees share a
  queue. Outside Git, the canonical project path is used.
- **Storage:** `$XDG_STATE_HOME/claude-message-queue` or
  `~/.local/state/claude-message-queue`.
- **Ordering:** a locked, monotonic sequence provides deterministic FIFO IDs,
  including for concurrent writers.
- **Safety:** atomic file moves and a short PID lock protect concurrent adds;
  stale locks left by killed writers are recovered automatically.
- **Lifecycle:** `pending → active → done`, with `active → pending` on retry.
- **Privacy:** state files are created with user-only permissions and never live
  inside the repository.

Override storage for an isolated environment:

```sh
export CLAUDE_QUEUE_STATE_DIR=/path/to/private/state
```

## Command reference

```text
claude-queue add MESSAGE...
claude-queue add --stdin
claude-queue list
claude-queue count
claude-queue peek
claude-queue claim
claude-queue show ID
claude-queue done ID
claude-queue retry ID
claude-queue remove ID
claude-queue clear --yes
claude-queue path
claude-queue doctor
```

Use `--project DIR` to address another project and `--state-dir DIR` for an
isolated state root.

## Test

```sh
./scripts/check.sh
```

The suite checks FIFO ordering, multiline payloads, claim/done/retry behavior,
concurrent writers, invalid IDs, queue sharing between Git worktrees, and the
plugin manifests and skills. CI runs it on macOS and Ubuntu.

## Why there is no monitor or channel

Anthropic's plugin monitors currently run only in interactive CLI sessions, not
Desktop. Channels inject events into a running session. Either would violate
this project's central promise: queued messages wait until current work is done.
The implementation therefore uses regular plugin skills and an explicit durable
backlog on both surfaces.

## Troubleshooting

- **A mid-turn message interrupts:** press Enter to queue it; Escape explicitly
  stops the current response. Update Claude Code and Claude Desktop.
- **A mid-turn message is dropped:** update to the current stable build. Desktop
  had a delivery fix after Claude Code 2.1.205.
- **`/queue:*` commands missing:** verify the plugin is enabled with `/plugin`,
  then run `/reload-plugins` or start a new local session.
- **CLI and Desktop show different durable queues:** run `claude-queue doctor`
  from both working directories and compare the `Identity` line.
- **Ordinary Desktop chat cannot see it:** open the **Code** tab. Claude Desktop
  chat extensions and Claude Code plugins use separate extension systems.

## References

- [Claude Code Desktop](https://code.claude.com/docs/en/desktop)
- [Claude Code plugins](https://code.claude.com/docs/en/plugins)
- [Claude Code plugin reference](https://code.claude.com/docs/en/plugins-reference)
- [Claude Code changelog](https://code.claude.com/docs/en/changelog)

## License

[MIT](LICENSE)
