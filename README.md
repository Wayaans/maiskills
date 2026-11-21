# maiskills

Personal agent skills by Wayan Ary, installable with the [skills](https://skills.sh) CLI.

## Install

```sh
npx skills add Wayaans/maiskills -g
```

Install one skill only:

```sh
npx skills add Wayaans/maiskills -g --skill unslop
```

Update installed skills:

```sh
npx skills update -g
```

## Skills

| Skill | What it does |
|---|---|
| [`pr-gate-quality`](skills/pr-gate-quality/SKILL.md) | Review and fix a PR in rounds with four parallel skill reviewers until it is ready to merge. |
| [`review-issue`](skills/review-issue/SKILL.md) | Review a GitHub issue against the codebase, write a detailed plan, and size it as a spec or a single ticket. |
| [`rex-handoff`](skills/rex-handoff/SKILL.md) | Hand the conversation off to a fresh Claude session in a new Rex tab. |
| [`rv-no-merge`](skills/rv-no-merge/SKILL.md) | Take a finished implementation through review, browser verification, and CI in separate threads until its PR is ready to merge, without merging it. |
| [`t3-handoff`](skills/t3-handoff/SKILL.md) | Hand the conversation off to a fresh T3 Code thread. |
| [`unslop`](skills/unslop/SKILL.md) | Cut AI tells from any writing. |
| [`verify-it-work`](skills/verify-it-work/SKILL.md) | Verify in a real browser that a change works as intended, scoped to the change and what directly touches it. |

Skills that set `disable-model-invocation: true` run only when called by name (for example `/review-issue`). The rest can also be invoked by the agent.

## Dependencies

`pr-gate-quality` uses four review skills from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) by Addy Osmani (MIT license) as its reviewer lenses:

- `code-review-and-quality`
- `code-simplification`
- `performance-optimization`
- `security-and-hardening`

Install them alongside:

```sh
npx skills add addyosmani/agent-skills -g --skill code-review-and-quality code-simplification performance-optimization security-and-hardening
```

## License

[MIT](LICENSE)
