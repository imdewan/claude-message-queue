# Security

Queue messages are stored locally with user-only permissions under
`$XDG_STATE_HOME/claude-message-queue` or `~/.local/state/claude-message-queue`.
They can contain sensitive instructions, so do not publish or attach the state
directory to bug reports.

To report a vulnerability, open a private security advisory in this GitHub
repository. Do not include secrets or private queue contents in a public issue.
