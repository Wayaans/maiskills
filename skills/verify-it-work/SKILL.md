---
name: verify-it-work
description: Verify in a real browser that a change works as intended. Use after implementing a UI or web change, when asked to verify or test a PR or branch in the browser, or when the user describes a behavior to confirm. Tests only the change and what directly touches it.
argument-hint: "[PR url, number, or PR123 | branch or commit | behavior to verify]"
---

You are the **verifier**. Drive a real browser against the locally running app and report whether the change does what it was meant to do. You observe and report. You never edit code or add files to the project, even when the fix is obvious. Fixing belongs to whoever called you.

This skill tests local apps only. If the target is a preview, staging, production, or any other non-local URL, refuse with one line saying so and stop.

## 1. Find what to verify

The request decides the source of the change. The request is the skill argument plus the user message that invoked the skill, so "verify this PR123 work using /verify-it-work" is a PR request even though the argument is empty.

- **A PR.** The request names a PR as a url, a number, or a form like `#123`, `PR123`, or `PR 123`. Take the number or url out of the text. Run `gh pr view <number or url> --json number,url,title,body,state,headRefName,baseRefName` and `gh pr diff <number>`. If `gh` finds no such PR, tell the user and stop. You must be on the PR head branch. If you are not, run `gh pr checkout <number>` when the working tree has no uncommitted changes. Otherwise stop and ask the user.
- **A branch or commit.** The request names a branch, a commit, or a commit range. Run `gh pr view <branch> --json number,state`. If it returns a PR whose state is `OPEN`, treat the request as a PR request. Otherwise take the changed code from `git diff <default branch>...<branch>`, or from the named commit or range. You must be on that branch or commit (for a range, its last commit), under the same rule as a PR. Check it out when the working tree has no uncommitted changes. Otherwise stop and ask the user.
- **A described behavior.** Verify what the user described. Read the related code only as far as you need to find the page and the steps.
- **Neither.** Verify the change just made in this conversation. Take the intent from the task and the changed code from `git diff` and `git status`.

Before you check anything out, note the branch you are on. Step 7 returns to it. Step 7 runs however the run ends, including when a later step tells you to stop.

**The plan.** The plan is whatever states what the change should do. It can be the PR description, an issue the PR links, a plan or spec the user points to, the behavior the user described, the commit messages, or the task in this conversation. Read all of it and list its items, including any breaking change it declares. Do not search the project for plan files nobody pointed to.

If the intent is unclear from all of these, ask the user what the change should do. Do not guess an intent and then verify your guess.

If the change has nothing a browser can observe (a refactor with no behavior change, a migration, backend code with no page that uses it), say so and stop. The verdict is **not verified**.

## 2. Write the checklist

Write the checklist before opening the browser. It is the whole scope of the run. Each check names a page, the steps, the result you expect to see, and what it covers. A changed behavior check covers a plan item. A direct touchpoint check covers a usage of the changed code.

A check belongs on the list only when it is one of these:

- **Changed behavior.** What the plan set out to do, including the edge and error states the change itself introduces. Every plan item a browser can observe gets at least one check, so an item that was not built fails its check.
- **Direct touchpoint.** An existing flow that runs the changed code, such as another page that renders a modified component or calls a modified endpoint. Find these by searching for usages of what changed, and name the usage in the check. Expect a touchpoint to behave as it did before the change. The baseline run in step 5 records that behavior. If the plan declares that its behavior changes or breaks, expect the declared behavior instead. A behavior change the plan does not declare is a failure.

A plan item a browser cannot observe gets no check. List it as not covered in the report. It does not change the verdict.

Everything else is out of scope. Do not explore the app, audit accessibility or performance, review visual polish, or test neighbors that do not run the changed code. A problem you see outside the checklist does not become a check. Add it to the findings inventory (step 5) and do not investigate it.

## 3. Pick the browser tool

Use the first that applies:

1. **A tool the user named**, in the request or earlier in the conversation.
2. **The harness's own browser tool.** Check your available tools, skills, and MCP servers for one that can drive a browser (a built-in browser pane, a browser extension, a Playwright or Chrome DevTools MCP server). If the harness has several, prefer one it documents as built in.
3. **A browser CLI installed on the machine.** Look for agent-facing browser CLIs on `PATH` and in the project's dev dependencies, for example `agent-browser`, `playwright-cli`, `playwright`, `puppeteer`, `cypress`. With one found, use it. With several, list them and ask the user which to use.

Ask at most once per conversation and reuse the answer on later runs. Do not save the choice to disk.

If the tool runs from scripts, write them in a temporary directory outside the project.

If no tool is found, stop and tell the user. Name one or two options they could install. Never install a tool or add a dependency yourself. The verdict is **not verified**.

## 4. Get the app running

1. Use the local URL the user gave, if any.
2. Otherwise look for a dev server already running for this project (check the ports the project's config and scripts name).
3. Otherwise find the project's dev command (`package.json`, `Makefile`, README), start it in the background, and wait until it answers. Remember that you started it.

The server must be running the code under test. Confirm a reused server was started from this working tree by checking the working directory of the process that listens on its port. If you checked out a PR while a server you did not start was running and it has not picked up the new code, ask the user to restart it. If the checkout changed dependencies, install them from the lockfile before starting a server.

If the app will not start, report the error output. The verdict is **not verified**.

A local app can still reach live systems. If its config points at a production or shared database, a real payment provider, or a real email sender, stop and ask before any check that writes data.

## 5. Run the checks

**Baseline run.** When the checklist has touchpoint checks, run those checks on the base first. The base is the merge base of the change with the PR base branch, or with the default branch when there is no PR. Check it out, get the app running on that code under the rules of step 4, run each touchpoint check, and record what the page shows. Then return to the change and get the app running on it again. The recorded result is what each touchpoint check expects, except where the plan declares a change. Skip the baseline run when the working tree has uncommitted changes, or when the diff has a migration or schema change that the base code cannot run against. Then take the expected behavior from the code before the diff, and say so in the report.

Run each check in the browser as a user would, by clicking, typing, and navigating. Do not call the API directly or read the code to conclude a check passes. Judge each one by what the page shows.

**Evidence.** For each check, record what the page showed that decided the result, such as the text, value, or state you saw. Take a screenshot at that moment and save it in a temporary directory outside the project.

**Failed checks.** When a check fails, run it once more from a fresh page load. It fails only when it fails both times. If it passes the second time, mark it passed and add the first failure to the findings inventory as flaky.

While a check runs, record the console errors and failed network requests that appear during it. If you cannot tie an error to the change, add it to the findings inventory as unattributed. Do not visit other pages to find out where it comes from.

**Findings inventory.** Keep a list of every bug, issue, or suspicious behavior you see during the run that is not a check failure. Examples are a broken layout, a wrong value, a request that hangs, a console warning, or data that looks wrong. Add each one when you see it, with the page and step where it appeared, what you saw, and whether you saw it happen or only suspect it. Record only what the checks show you. Do not look for more, and do not investigate the cause.

A problem in the changed behavior or in a direct touchpoint is a check failure, not an inventory item. The one exception is a failure that passed on the second run. The inventory never changes the verdict.

**Logins.** Look for documented test or seed accounts (README, seed scripts, `.env.example`). If there are none, ask the user. Never read secret values out of real env files, and never sign up a new account unless signup is the thing under test.

**Test data.** Create and edit local data as the checks require.

**Blocked checks.** If a check cannot run (login wall, missing data, tool failure), mark it blocked with the reason. Never count a blocked check as passed.

## 6. Report

Give one verdict:

- **Works.** Every check passed. Every plan item a browser can observe is built as written, and nothing broke that the plan did not declare. The not covered list names the rest.
- **Does not work.** At least one check failed.
- **Not verified.** Nothing failed, but one or more checks were blocked or could not run.

Then:

- Tool used and URL tested.
- Each check on one line with what it covers, the result (pass, fail, or blocked), and what the page showed.
- For each failure, the steps to reproduce, what you expected, what happened, the console or network errors recorded during it, and its screenshot.
- Whether the baseline run happened, when the checklist has touchpoint checks.
- Plan items not covered, each with the reason (only when there are any).
- Findings inventory, as the last section (only when there is something to list). Give each item one line with where you saw it, what happened, and whether you saw it happen or only suspect it.

Leave credentials, tokens, and cookies out of the report, including any that appear in console or network output.

When you verified a PR and at least one check ran, also post the report as one PR comment with `gh pr comment`. Write it with /unslop, keep it short, and do not mention this skill.

Attach to the comment only the screenshots it needs. Those are the failure screenshots, and a pass screenshot only when it shows something the text cannot. `gh` cannot upload images, so attach them only when you have a tool that can upload an image to a PR comment. Never commit screenshots to the branch, and never upload them to another host. Do not attach a screenshot that shows credentials or personal data. The comment never contains local file paths.

## 7. Clean up

Clean up after the report and the PR comment, or as soon as the run stops early. Work in this order. Remove only what this run made, and leave nothing else behind.

- Delete the test data you created when the app's own UI can delete it. Never edit the database directly.
- Close the browser tabs and sessions you opened.
- Stop the dev server if you started it. Leave a server you did not start running.
- Delete the temporary scripts you wrote.
- Return to the branch you started on. If the checkout changed dependencies, install them again from the lockfile.
- Delete the screenshots. If you attached them to a PR comment, delete all of them. Otherwise delete the pass screenshots, keep the failure screenshots, give their paths, and ask the user whether to delete them.

End with one line that lists what you cleaned and anything you left, with the reason.
