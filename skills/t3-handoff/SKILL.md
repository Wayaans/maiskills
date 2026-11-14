---
name: t3-handoff
description: Hand the current conversation off to a fresh T3 Code thread that picks up the work immediately.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff summary of the current conversation so a fresh agent can continue the work. Instead of saving it, launch a new top-level T3 Code thread seeded with the summary as its first message: call the `t3_thread_launch` tool (load it with ToolSearch if needed) with `title` set to a descriptive name and `message` set to the handoff summary. It returns immediately; the user manages the new thread from the T3 sidebar.

Always pass a descriptive `title` (e.g. `"Fix login bug"`); it is the thread name shown in the sidebar.

Start the thread in the current working directory. Omitting `workspaceStrategy` selects the project root, not the caller's worktree, so if the current session runs in a git worktree pass `{"type":"existing_worktree","worktreePath":"<absolute path>","branch":"<current branch>"}`; otherwise pass `{"type":"root"}`. Omit `projectId`, `modelSelection`, and modes so they inherit from the current thread.

Launches have no retry key. Retain the returned `threadId`; if the call errors or its response is lost, check `t3_thread_list` before retrying so you don't create a duplicate thread.

Include a "suggested skills" section in the summary, naming which skills the next agent should call the Skill tool for.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information, since the summary becomes the agent's prompt.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the summary accordingly.
