---
name: rex-handoff
description: Hand the current conversation off to a fresh Claude session in a new background tab of the current Rex session.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff summary of the current conversation so a fresh agent can continue the work. Save it to the temporary directory of the user's OS.

Then find the Rex session this conversation is shown in. Don't pass `$REX_SESSION` directly: background Claude jobs inherit it from whichever pane started the Claude daemon, so it can name a different session. Run the resolver next to this file:

```sh
session=$(~/.agents/skills/rex-handoff/resolve-session.sh)
```

It prints the session ID. If it exits non-zero, it couldn't tell (several or no candidate sessions, listed on stderr). Show the user the candidates with their labels from `rex session ls --json` and ask which one to use. Don't guess.

Open a new background tab in that session running Claude seeded with the summary:

```sh
rex window new -s "$session" "<name>" -c "$PWD" --focus=false --json -- \
  sh -c 'claude --name "$1" --permission-mode "$2" -- "$(cat "$3")"' sh "<name>" "<mode>" "<summary file>"
```

Passing the file through `sh -c` keeps the shell from running backticks or expanding `$` in the summary. It starts in the current working directory and returns immediately; the user switches to the tab when ready.

Always use a descriptive `<name>` (e.g. `"Fix login bug"`); it becomes both the tab name and the Claude session name.

Set `<mode>` to this session's current permission mode so the new session behaves the same: one of `acceptEdits`, `auto`, `bypassPermissions`, `manual`, `dontAsk`, `plan`.

If `rex` can't reach a server, run `rex whoami --json` to check. If you aren't running inside Rex, stop and tell the user instead of falling back to another launcher.

Retain the returned `window_id`. If the command times out, check `rex window ls -s "$session" --json` before retrying so you don't open a duplicate tab.

Include a "suggested skills" section in the summary, naming which skills the next agent should call the Skill tool for.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information, since the summary becomes the agent's prompt.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the summary accordingly.
