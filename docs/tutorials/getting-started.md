# Getting started

This tutorial takes you from a fresh clone to your first successful
`pulumi preview` against the real project state. By the end, you'll have a
working local setup and have seen, concretely, what this project actually
manages.

## Prerequisites

- [Pulumi CLI](https://www.pulumi.com/docs/install/) installed
- [uv](https://docs.astral.sh/uv/) installed (this project's Python
  toolchain)
- A [Pulumi Cloud](https://app.pulumi.com/) account, and a Pulumi access
  token exported as `PULUMI_ACCESS_TOKEN`
- A GitHub personal access token with permission to manage repositories in
  your target organization
- [GitHub CLI](https://cli.github.com/) (`gh`), authenticated, for
  verifying results later in this tutorial

## Step 1: Clone the repository

```console
$ git clone https://github.com/phrankson/platform-team-admin.git
$ cd platform-team-admin
```

## Step 2: Select the stack

This project has one Pulumi stack, `dev`, already initialized:

```console
$ pulumi stack select dev
```

## Step 3: Configure your GitHub credentials

Pulumi needs to know which GitHub organization to manage and what token to
use. Set both as stack config — the token is marked `--secret` so Pulumi
encrypts it at rest:

```console
$ pulumi config set github:owner <your-github-org>
$ pulumi config set github:token <your-github-token> --secret
```

You can confirm both are set (the token's value will be masked):

```console
$ pulumi config
KEY            VALUE
github:owner   <your-github-org>
github:token   [secret]
```

## Step 4: Install Python dependencies

Pulumi's toolchain for this project is `uv`, configured in
[`Pulumi.yaml`](../../Pulumi.yaml). Running any `pulumi` command will
provision the virtual environment automatically the first time, but you
can also do it explicitly:

```console
$ uv venv .venv
$ source .venv/bin/activate
$ uv pip install -e .
```

## Step 5: Preview the current state

This is the step that proves everything is wired up correctly. `pulumi
preview` reads [`config/platform_team_values.yaml`](../../config/platform_team_values.yaml),
compares it against what actually exists in your GitHub organization, and
reports the difference — without changing anything.

```console
$ pulumi preview
```

If your organization already has every repository this project declares,
you should see something like:

```console
Previewing update (dev)

     Type                 Name                              Plan
     pulumi:pulumi:Stack  platform-team-administration-dev

Resources:
    14 unchanged
```

`14 unchanged` means Pulumi checked every repository and branch protection
rule this project manages and found no drift — reality already matches
what's declared. This is the successful outcome: a clean preview against a
real, live GitHub organization.

## What you've done

You now have a working local setup that can read the true state of every
repository this project manages, without having changed anything. From
here:

- To make an actual change, see [Add a repository](../how-to/add-a-repository.md).
- To understand every field in the config file you just read, see the
  [configuration schema reference](../reference/config-schema.md).
