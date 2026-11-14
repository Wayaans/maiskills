---
name: pr-gate-quality
description: Review and fix a PR in rounds with four parallel skill reviewers until it is ready to merge.
argument-hint: "<PR url or number>"
---

You are the **fixer**. Four reviewer subagents each apply one review skill; you merge their findings, fix them, and push. Keeping each lens in its own reviewer lets every review go deep while you stay focused on fixing.

**Requires** four review skills by Addy Osmani ([addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), MIT): `code-review-and-quality`, `code-simplification`, `performance-optimization`, `security-and-hardening`. Before step 3, check that `~/.claude/skills/<skill>/SKILL.md` exists for each. If any is missing, stop and tell the user to run:

```
npx skills add addyosmani/agent-skills -g -y --skill code-review-and-quality code-simplification performance-optimization security-and-hardening
```

Work autonomously: fix, commit, and push without asking. Pause for the user's confirmation only before a **destructive** step: deleting files or branches, discarding uncommitted work, rewriting history, force-pushing, or closing or merging the PR. Merging stays with the user.

## 1. Read the PR

Run `gh pr view <arg> --json number,url,title,body,state,headRefName,baseRefName` and `gh pr diff <number>`. The PR must be open.

You must be on the PR head branch. If you are not, run `gh pr checkout <number>` when the working tree has no uncommitted changes; otherwise stop and ask the user.

## 2. Scan (optional)

Read surrounding code only where you need it to understand the diff. Edit nothing yet.

## 3. Review

The active reviewers start as all four skills: `code-review-and-quality`, `code-simplification`, `performance-optimization`, `security-and-hardening`.

In one message, spawn one reviewer subagent per active skill, in parallel, each briefed with the reviewer prompt below. Wait for all of them to report.

A reviewer that returns no major or medium findings (or N/A) is **clean**: drop it from the active reviewers for later rounds.

## 4. Fix

Merge the reports with the PR's unresolved review threads from humans and bots (query `reviewThreads` with `isResolved` through `gh api graphql`). Collapse duplicates and settle conflicts between reviewers by picking the option that best serves correctness, then clarity.

- Fix every major and medium finding and every unresolved review thread.
- Fix minor findings when the fix is small and clearly better; otherwise keep them for the report.
- Decline a finding only when it is wrong or outside the PR's scope, and record the reason for the report and for later reviewer prompts.

Keep each change inside the code the PR touches. Then run the repo's own test, typecheck, lint, and build commands (find them in `package.json`, `Makefile`, or CI config). Everything that passed before must still pass.

## 5. Push

Commit with a message naming the round and what it fixed, then push to the PR branch as a normal follow-up commit.

- Post one PR comment for the round (`gh pr comment`) listing each issue, its fix, and the commit SHA, one line per issue.
- Write that comment and every thread reply with /unslop. Keep them short, and never mention the gate or this skill.
- For each review thread: if fixed, reply with what changed and the commit SHA, then resolve it; if declined, reply with the reason and leave it open.

## 6. Re-review

Return to step 3 with the remaining active reviewers. When every reviewer is clean, run one last round with the reviewers dropped earlier, scoped to the fix commits only (`git diff <first-round head>...HEAD`).

Stop when that last round is clean and no review thread is left unanswered.

After every 5 rounds without finishing, pause: tell the user what remains and ask whether to run another 5 rounds.

## 7. Report

A concise summary:

- Number of review rounds.
- Per reviewer: rounds until clean, findings fixed.
- Review threads fixed or declined, with reasons for declines.
- Minor findings left unfixed.
- Verdict: **ready to merge**, or what still blocks it.

## Reviewer prompt

```
You are a read-only reviewer for PR #<number> (<url>). Base: <baseRefName>.
Read ~/.claude/skills/<skill>/SKILL.md and apply it as your review lens.
Review only the PR's changes (`git diff origin/<baseRefName>...HEAD`); read surrounding code only to judge them.
Edit nothing.
Already declined (do not re-raise unless the reason is wrong; then say why):
<finding | reason, one per line, or "none">
Return one line per finding: <major|medium|minor> | <file:line> | <issue> | <concrete fix>.
If your lens does not apply to this diff, return exactly: N/A, with one line saying why.
```
