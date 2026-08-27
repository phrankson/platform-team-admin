# How to install git hooks

This repo enforces [Conventional Commits](https://www.conventionalcommits.org/)
(`type(scope): description`) via a local `commit-msg` hook. Git does not
sync `.git/hooks/` between clones, so this is a manual, one-time step per
clone.

## Install

```console
$ ./scripts/install-githooks.sh
Successfully installed commit-msg hook
Git hooks installation complete
  Source:  <repo>/.git-hooks/commit-msg
  Target:  <repo>/.git/hooks/commit-msg
Commit messages will now be validated for conventional commits format
```

## Verify

```console
$ git commit --allow-empty -m "not a valid message"
Error: Commit message does not follow conventional commits format

Valid format: type(scope)?: description

Allowed types: build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test
```

A correctly formatted message should commit without any output from the
hook:

```console
$ git commit --allow-empty -m "chore: test the commit hook"
```

## Bypassing the hook

`git commit --no-verify` skips this check entirely. This is expected —
the hook is a fast, local convenience check, not the actual enforcement
mechanism. Every repository this project manages also has server-side
branch protection requiring signed commits and (depending on
configuration) review approval, which cannot be bypassed the same way.
See [Architecture and design choices](../explanation/architecture-and-design-choices.md#two-layers-of-enforcement)
for why both layers exist.
