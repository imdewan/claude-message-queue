#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
queue="$repo_dir/bin/claude-queue"
test_root="$(mktemp -d)"

cleanup() {
  rm -rf "$test_root"
}
trap cleanup EXIT INT TERM

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  [[ "$expected" == "$actual" ]] || fail "$label (expected '$expected', got '$actual')"
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"
  [[ "$haystack" == *"$needle"* ]] || fail "$label (missing '$needle')"
}

export CLAUDE_QUEUE_STATE_DIR="$test_root/state"
main_repo="$test_root/project"
worktree="$test_root/worktree"

mkdir -p "$main_repo"
git -C "$main_repo" init -q
git -C "$main_repo" -c user.name='Queue Test' -c user.email='queue@example.invalid' commit --allow-empty -qm init
git -C "$main_repo" worktree add -q "$worktree"

first_id="$($queue --project "$main_repo" add -- 'first queued task')"
second_id="$(printf 'second task\nwith two lines\n' | $queue --project "$main_repo" add --stdin)"

assert_eq "2" "$($queue --project "$main_repo" count)" "two messages are pending"
assert_eq "2" "$($queue --project "$worktree" count)" "Git worktree shares the queue"
assert_contains "$($queue --project "$main_repo" list)" "$first_id" "list includes first ID"
assert_contains "$($queue --project "$main_repo" list)" "$second_id" "list includes second ID"
assert_eq "first queued task" "$($queue --project "$main_repo" peek)" "peek is FIFO"

claimed_id="$($queue --project "$worktree" claim)"
assert_eq "$first_id" "$claimed_id" "claim returns oldest ID"
assert_eq "first queued task" "$($queue --project "$main_repo" show "$claimed_id")" "show reads active message"
assert_eq "1" "$($queue --project "$main_repo" count)" "active messages are excluded from pending count"
assert_contains "$($queue --project "$main_repo" list)" "Active: 1" "list reports an active message"

$queue --project "$main_repo" retry "$claimed_id" >/dev/null
assert_eq "2" "$($queue --project "$main_repo" count)" "retry preserves the message"
assert_eq "$first_id" "$($queue --project "$main_repo" claim)" "retried message keeps FIFO position"
$queue --project "$main_repo" done "$first_id" >/dev/null
assert_eq "1" "$($queue --project "$main_repo" count)" "done removes only the active message"

multiline="$($queue --project "$main_repo" show "$second_id")"
assert_eq $'second task\nwith two lines' "$multiline" "stdin preserves multiline content"
$queue --project "$main_repo" remove "$second_id" >/dev/null
assert_eq "0" "$($queue --project "$main_repo" count)" "remove empties the queue"

for number in 1 2 3 4 5 6 7 8; do
  "$queue" --project "$main_repo" add -- "concurrent $number" >/dev/null &
done
wait
assert_eq "8" "$($queue --project "$main_repo" count)" "concurrent adds are not lost"

previous_id=""
while IFS= read -r line; do
  current_id="$(printf '%s\n' "$line" | awk '{print $2}')"
  if [[ -n "$previous_id" && "$current_id" < "$previous_id" ]]; then
    fail "concurrent IDs must remain monotonically ordered"
  fi
  previous_id="$current_id"
done < <("$queue" --project "$main_repo" list | awk '$1 == "pending"')

clear_output="$($queue --project "$main_repo" clear --yes)"
assert_contains "$clear_output" "cleared 8 message(s)" "clear reports removed messages"
assert_eq "0" "$($queue --project "$main_repo" count)" "clear empties the queue"

queue_path="$($queue --project "$main_repo" path)"
mkdir "$queue_path/.lock"
printf '99999999\n' > "$queue_path/.lock/pid"
recovered_id="$($queue --project "$main_repo" add -- 'recovered after stale lock')"
assert_eq "recovered after stale lock" "$($queue --project "$main_repo" show "$recovered_id")" "stale lock is recovered"
$queue --project "$main_repo" remove "$recovered_id" >/dev/null

if "$queue" --project "$main_repo" show '../bad' >/dev/null 2>&1; then
  fail "invalid IDs must be rejected"
fi

assert_contains "$($queue --project "$main_repo" doctor)" "Status: OK" "doctor succeeds"

printf 'PASS: lifecycle, FIFO, concurrency, stale-lock recovery, and worktree sharing\n'
