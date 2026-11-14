#!/bin/sh
# Prints the ID of the Rex session the invoking Claude conversation is shown in.
# Exits 1 when it can't tell, listing any candidate sessions on stderr.
set -eu

# A foreground Claude inherits its pane's environment, so a live REX_BLOCK pins the session.
# Background jobs run in processes the Claude daemon spawned ahead of time, which carry the
# environment of whichever pane started the daemon, so their REX_* values can't be trusted.
if [ -z "${CLAUDE_JOB_DIR:-}" ] && [ -n "${REX_SESSION:-}" ] && [ -n "${REX_BLOCK:-}" ] &&
  rex block inspect -s "$REX_SESSION" "$REX_BLOCK" >/dev/null 2>&1; then
  echo "$REX_SESSION"
  exit 0
fi

# Otherwise find panes running `claude` in this directory or one of its parents (a job may
# run in a worktree below where it was started). The deepest match wins.
matches=$(
  rex session ls --json | jq -r '.sessions[].session_id' | while read -r session; do
    rex window ls -s "$session" --json |
      jq -r '.windows[].layers[].blocks[].block_id' | while read -r block; do
        rex block call -s "$session" -b "$block" process 2>/dev/null |
          jq -r --arg s "$session" --arg pwd "$PWD" '
            .foreground // empty
            | select(.argv0 == "claude" and .cwd != null)
            | select(.cwd as $cwd | $pwd == $cwd or ($pwd | startswith($cwd + "/")))
            | "\(.cwd | length) \($s)"' || true
      done
  done
)

best=$(printf '%s\n' "$matches" | sort -rn | awk 'NR == 1 { depth = $1 } $1 == depth && NF { print $2 }' | sort -u)
count=$(printf '%s' "$best" | grep -c . || true)

if [ "$count" -eq 1 ]; then
  echo "$best"
  exit 0
fi

if [ "$count" -eq 0 ]; then
  echo "No Rex pane is running claude in $PWD." >&2
else
  echo "Several Rex sessions run claude in this directory:" >&2
  printf '%s\n' "$best" >&2
fi
exit 1
