---
name: review-issue
description: Review a GitHub issue against the codebase, write a detailed plan, and size it as needing a spec or a single ticket.
disable-model-invocation: true
---

Read a GitHub issue, compare what it asks for with what the code does today, and give the user a plan in chat. The skill is read-only. It never edits files, labels issues, or posts comments. Publishing belongs to `/to-spec` and `/to-tickets`.

The argument is an issue number, `owner/repo#N`, or a URL. If none was given, ask for one and stop.

## Steps

### 1. Read the issue

Run `gh issue view <ref> --comments` from the repo. Read the body, every comment, labels, and linked issues or PRs. Follow each link that changes the requirement.

Done when you can restate the issue as a list of **requirements**, each one a behaviour the user expects. Comments often narrow or override the original body; the latest agreed version wins. If two comments conflict with no resolution, record it as an open question.

### 2. Compare with the codebase

For each requirement, find where that behaviour lives or would live. Search by domain concept, not only the issue's wording, because reporters rarely use the code's names. Read `GLOSSARY.md` and ADRs in the area if they exist, and use their terms.

Give each requirement a status:

- **done**: the code already does it.
- **partial**: some of it exists.
- **missing**: nothing exists yet.
- **conflict**: the code, an ADR, or another requirement contradicts it.

Done when every requirement has a status backed by **evidence**: a `path:line` or a search you ran that came back empty. A status without evidence is a guess; go back and look.

If every requirement is **done**, report that with the evidence and skip to step 6.

### 3. Settle open decisions

An **open decision** is a product or design choice that neither the issue nor the code answers: unresolved discussion in the comments, a requirement in **conflict**, or behaviour the issue leaves vague. Facts you can look up are not open decisions; look them up.

If there are none, go to step 4. Otherwise, load the `grilling` skill (what `/grill-me` runs) and interview the user on them. Seed the design tree with the open decisions, and give each question the code evidence from step 2 so the user decides with the current state in view.

Done when every open decision is either answered by the user or **parked**, meaning the user says someone else has to decide it. Update each requirement's status to match the answers.

### 4. Size the work

Call it **spec** when any of these hold:

- A decision is still parked.
- The work crosses several modules or subsystems, or changes a schema, public API, or data contract.
- It needs more than one vertical slice to deliver.
- A requirement is still in **conflict**.

Call it **ticket** when all of these hold:

- One vertical slice delivers it.
- The issue, the code, and the user's answers settle every decision.
- An agent can build and verify it in a single fresh context window.

When the signals are mixed, name the signal that tipped it.

### 5. Write the plan

Write the plan in chat using the template below. Steps must be concrete enough that someone who has not read the issue could start work: name the files, the change, and how to verify it.

<plan-template>

## Issue

What it asks for, in two or three sentences of your own words. Link the issue.

## Current state

What the code does today in this area, with `path:line` evidence.

## Requirements

| Requirement | Status | Evidence |
| --- | --- | --- |

## Decisions

Each decision from step 3 with the user's answer, or who it is parked with. Omit the section if step 3 found none.

## Plan

Numbered steps in build order. Each step names the files or areas it touches, the change, and how to verify it. Put any prefactor first.

## Risks and open questions

Each risk with what could break. Each question with who can answer it (reporter, maintainer, code owner).

## Size: spec or ticket

The call, the signals behind it, and the next step.

</plan-template>

### 6. Point to the next step

- **spec**: run `/to-spec` with this plan in context, then `/to-tickets` on the spec.
- **ticket**: the plan above is the ticket. Run `/to-tickets` to publish it, or build it directly.
- **already done**: suggest closing the issue with a comment pointing to the evidence. Leave the closing to the user.

If a parked decision blocks the sizing call, name it and say which answer would flip it.
