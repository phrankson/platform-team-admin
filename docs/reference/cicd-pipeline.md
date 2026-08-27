# CI/CD pipeline reference

Full reference for [`.circleci/config.yml`](../../.circleci/config.yml).

## Orb

`pulumi/pulumi@2.1.0` — provides the `pulumi/login`, `pulumi/preview`, and
`pulumi/update` commands used below. It does not provide jobs or an
executor; each job runs these as steps against a plain Docker image.

## Context

`PLATFORM_ADMIN` — applied to every job. Holds `PULUMI_ACCESS_TOKEN`,
used by `pulumi/login`.

## Jobs

| Job | Image | Steps |
|---|---|---|
| `pulumi-preview` | `cimg/python:3.10` | Checkout → install `uv` → `pulumi/login` → `pulumi/preview` against stack `dev`. |
| `pulumi-up` | `cimg/python:3.10` | Checkout → install `uv` → `pulumi/login` → `pulumi/update` against stack `dev`. |

## Triggers

| Filter | Matches |
|---|---|
| `push_main` | Any push to the `main` branch. |
| `tag_main` | Any tag matching `/^v.*/`, and explicitly ignores all branches. |

## Workflows

### `preview`

Runs `pulumi-preview` on every push to `main`. Provides fast feedback on
what would change — applies nothing.

### `update`

Runs on a version tag (`v*`):

1. `pulumi-preview` — re-confirms what will change against the tagged
   commit.
2. `approve-deployment` — a manual approval gate (CircleCI `type:
   approval`). Must be triggered from the CircleCI UI.
3. `pulumi-up` — runs only after `approve-deployment` completes,
   applying the change for real.

A push to `main` alone never applies anything. Applying requires both a
version tag and a human clicking approve.
