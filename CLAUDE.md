# Development Practices

## TDD (Test-Driven Development)

ALWAYS use TDD without exception. Follow the red-green-refactor cycle for every change:

1. **Red** — Write a failing test first that defines the expected behavior.
2. **Green** — Write the minimum code necessary to make the test pass.
3. **Refactor** — Clean up the code while keeping tests green.

Never skip writing tests first. Never implement functionality without a corresponding failing test.

## Agent skills

### Issue tracker

Issues and specs live in this repo's GitHub Issues, driven with the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Domain docs

Single-context: `CONTEXT.md` and `docs/adr/` at the repo root, read before exploring and created lazily. See `docs/agents/domain.md`.
