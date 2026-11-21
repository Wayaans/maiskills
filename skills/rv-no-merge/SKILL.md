---
name: rv-no-merge
description: Take a finished implementation through review, browser verification, and CI until its PR is ready to merge, without merging it.
argument-hint: "[PR url or number]"
disable-model-invocation: true
---

You are the **orchestrator**. You implemented the change in this conversation and its PR is already open. You now take that PR through three stages in order: review, verify, CI. You stop when the PR is ready to merge. You never merge it.

**Requires** the `pr-gate-quality` and `verify-it-work` skills, plus what `pr-gate-quality` itself requires. If either is missing, stop and tell the user to install it.

Review and verify each run in their own **thread**: a separate agent session in a new tab, never a subagent of yours. The thread does the work with its own skill and reports back to you. Everything else may use subagents, including the threads themselves.

Work autonomously. Ask the user only when:

- an issue is big: it changes the design, reaches outside the PR's scope, or you disagree with the finding;
- a thread reports that it needs the user;
- a stage has gone 3 fix rounds without passing.

## 1. Preflight

Find the PR: the one named in the request, otherwise `gh pr view --json number,url,title,body,state,headRefName` for the current branch. Note the issue it addresses, if any.

The PR must already be open. If there is none, stop and tell the user. Do not create one.

Commit and push any pending work for this change. Both threads need a clean working tree on the PR head branch.

The threads share your working tree. Run one thread at a time, and edit nothing while a thread is working.

## 2. Threads

Use the thread tool of the harness you are running in. If you are in neither Rex nor T3 Code, stop and tell the user. Do not fall back to subagents.

**Rex.** A thread is a new background tab running Claude. Your own address is `$REX_SESSION` and `$REX_BLOCK`. Check them with `rex block inspect -s "$REX_SESSION" "$REX_BLOCK"`. If that fails, or `CLAUDE_JOB_DIR` is set (a background job inherits another pane's values), ask the user which session and pane you are in.

Write the thread prompt to a file in the OS temp directory, then:

```sh
rex window new -s "$REX_SESSION" "<name>" -c "$PWD" --focus=false --json -- \
  sh -c 'claude --name "$1" --permission-mode "$2" -- "$(cat "$3")"' sh "<name>" "<mode>" "<prompt file>"
```

Passing the file through `sh -c` keeps the shell from breaking on the quotes and `&&` in the prompt. Set `<mode>` to this session's permission mode. Keep `.block_ids[0]` from the output: it is the thread's address. If the command times out, check `rex window ls -s "$REX_SESSION" --json` before retrying, so you don't open a duplicate tab.

To message a thread again, type into its pane:

```sh
rex send -s "$REX_SESSION" -b "<thread block>" '<message>' &&
  rex send-key -s "$REX_SESSION" -b "<thread block>" enter
```

The thread reports back the same way, to your block.

**T3 Code.** A thread is a new top-level thread from `t3_thread_launch` (load the T3 thread tools with ToolSearch), started in the current working directory as the t3-handoff skill describes. Keep the returned `threadId`. You and the thread message each other with T3's thread message tool, each addressing the other's thread ID.

**Thread prompts.** Keep them to the task and the report line. The skill carries the rest, so add no review focus, no checklist, and no summary of the change.

```
<task line>
When you finish, or when you would otherwise stop to ask the user, report back to the orchestrator: <how>.
```

`<how>` in Rex: `run rex send -s <orchestrator session> -b <orchestrator block> '<your report>' && rex send-key -s <orchestrator session> -b <orchestrator block> enter`. In T3: `send the report as a message to thread <orchestrator thread ID>`. Fill in your own IDs before you send the prompt.

**Waiting.** After you spawn or message a thread, tell the user which tab you are waiting on and that any permission prompt from the thread appears there. Then end your turn. Its report arrives as a new message.

**Reuse.** Each stage keeps one thread. Send every re-review to the review thread and every re-verify to the verify thread. Spawn a replacement only when the thread is gone.

## 3. Review

Spawn the review thread:

```
Review PR #<number> using /pr-gate-quality.
```

Add `It addresses issue #<n>.` when the PR body does not link the issue.

The review thread fixes what it finds and pushes. You do not fix review findings yourself. When it reports:

- **Ready to merge, and you accept what it left.** Go to step 4.
- **It left something you judge worth fixing**, such as a minor finding it kept for the report or a finding it declined. Tell the review thread what to fix and why, then wait for its next report.
- **Blocked, or it needs the user.** Resolve what you can. Otherwise ask the user, then pass the answer to the thread.

## 4. Verify

Spawn the verify thread:

```
Verify PR #<number> works in the browser using /verify-it-work.
```

The verify thread never edits code. When it reports:

- **Works.** Go to step 5. No re-review.
- **Does not work.** Fix the failures yourself, commit, and push. Then send the review thread `Re-review PR #<number> using /pr-gate-quality, only the commits <sha>..HEAD.` and wait for it to report clean, as in step 3. Then send the verify thread `Verify PR #<number> again using /verify-it-work.` Repeat until the verdict is Works.
- **Not verified.** If the change has nothing a browser can observe, go to step 5 and say so in the final report. If checks were blocked, clear the blocker or ask the user, then send it to verify again. A blocked check never counts as passed.

## 5. CI

Trigger the PR's checks the way the project does it. Read the project's rules first (`CLAUDE.md`, `AGENTS.md`, the CI config), because some projects do not run CI on push. Ask the user how to trigger it only when the rules and the config don't tell you.

Watch the run until it finishes.

- **Red.** Read the failing job's log, fix the cause, commit, push, and trigger CI again. Rerun without a change only when the failure is unrelated to the code and flaky.
- **Green.** Go to step 6.

If the PR has no checks at all, say so in the report and go to step 6.

## 6. Report

Give the user a brief summary:

- The PR, and that it is **ready to merge**.
- Review: rounds, and anything left unfixed or declined, with the reason.
- Verify: the verdict, and anything not covered.
- CI: the result.
- What you fixed yourself after verify or CI.
- The thread tabs left open.

Do not merge the PR. Leave the threads open for the user to close.
