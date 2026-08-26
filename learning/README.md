# Learning: platform-team-administration

A teaching companion for this repo, for a technical PM learning platform
engineering hands-on. This one file won't do it justice, so the deep dives
live alongside it:

1. **[Repos and Governance](repos-and-governance.md)** — declaring repos as
   code, and what branch protection actually enforces and why.
2. **[Hooks and CI/CD](hooks-and-cicd.md)** — why two layers of enforcement
   exist, secrets management, and the push-vs-tag deployment pattern.

> **How to use this:** the boxes marked "Predict before reading on" are
> collapsed — try to answer before opening them. Every `$` command is real,
> run against this project's actual live infrastructure.

---

## Start with a scene, not a definition

Imagine you're the head of a small city's Department of Buildings and
Planning. New construction crews show up every month wanting to build
something. Without your department, here's what happens: each crew
improvises. One crew wires the electrical to code because their foreman
happens to know the code. Another doesn't, because their foreman doesn't.
One crew keeps meticulous records of who signed off on what; another
crew's paperwork is a shoebox of receipts. Six months later, when a wall
needs repairing, nobody can even agree on who's allowed to authorize the
work.

Nothing in that story is *malicious*. Every crew is trying to build
something good. The problem is structural: safety and consistency were
left up to whichever individual happened to remember to care that day, and
individual memory doesn't scale past a handful of people.

A Department of Buildings and Planning fixes this not by inspecting every
nail, but by doing four specific things, once, centrally:

1. **Issuing permits** — a real, tracked, numbered record that a specific
   parcel exists and belongs to a specific project.
2. **Enforcing a building code** — a fixed set of rules every permit is
   subject to (wiring standards, signed-off inspections), applied the same
   way regardless of who's building or how experienced they are.
3. **Regulating utility hookups** — water, gas, and power don't get run by
   a crew tapping the main themselves; they go through a permitted,
   auditable connection process.
4. **Requiring inspection before occupancy** — a building doesn't go from
   "blueprint" to "people living in it" in one step. Someone checks the
   work first.

This repo is that department, and the "city" is your GitHub organization.
It doesn't write application code any more than a buildings department
pours concrete — its entire job is making sure every repo that exists,
exists with the same guarantees, automatically, because a machine enforces
them instead of a person remembering to.

## Why this is a *platform team's* job, not everyone's

In most engineering orgs, the teams building products are called
**stream-aligned teams** — they own a slice of the business (checkout,
billing, search) and their customers are the company's actual end users. A
**platform team** is different in a specific way worth naming: its
customers are the *other engineering teams*. Its "product" is the paved
road every stream-aligned team drives on — repos, pipelines, secrets,
clusters — so that no stream-aligned team has to become an expert in branch
protection policy or secrets rotation just to ship a feature.

This reframes something that might otherwise look like bureaucracy: a
platform team centralizing repo creation isn't control for its own sake,
the same way a buildings department isn't in the business of making
construction harder. It's the only way consistency and safety survive
contact with more than one team, because it moves the guarantee from "a
person remembers" to "a machine enforces."

## Why "as code" specifically — the idea underneath every file in this repo

Every one of the four department functions above could, in theory, be done
by a human clicking through a web form each time. This repo does none of
them that way. Instead, everything is declared in
[`config/platform_team_values.yaml`](../config/platform_team_values.yaml)
and a program —
[`pulumi_repo_create.py`](../pulumi_repo_create.py) — makes reality match
that file.

This is **declarative infrastructure**, and the distinction from clicking
through a UI is not cosmetic:

- **A declared thing can be reviewed before it happens.** A pull request
  changing `platform_team_values.yaml` shows exactly what will change,
  before it changes — the same way a permit application is reviewed
  *before* the crane shows up, not after.
- **A declared thing can be diffed against reality.** `pulumi preview` can
  answer "does what actually exists match what we said should exist?" A
  city can't run that check against a UI click that happened eleven months
  ago and left no trace of why.
- **A declared thing doesn't depend on one person's memory.** The eleven
  settings a repo needs are eleven lines in a file, not eleven steps a
  human has to remember to click through correctly, the same way every
  time, forever.

Pulumi's job, concretely, is: read the file, compare it to what's actually
true on GitHub right now, and issue only the API calls needed to close the
gap. That's the whole mechanism — not magic, just "diff, then reconcile."

**Try it yourself** — every repo below is real, created purely because a
line exists in `platform_team_values.yaml`, not because anyone clicked
"New repository" in GitHub's UI:

```console
$ gh repo list phrankson --limit 6
phrankson/platform-services      public
phrankson/platform-core          public
phrankson/platform-team-admin    public
phrankson/platform-gitops        public
phrankson/platform-extensions    public
phrankson/platform-demo-apps     public
```

Continue to [**Repos and Governance**](repos-and-governance.md) for how the
permit-and-code-enforcement half of this actually works, including a real
deadlock this project hit when two individually-correct rules collided.
