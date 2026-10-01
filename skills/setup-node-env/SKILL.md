---
name: setup-node-env
description: Sets up a project's Node.js environment — detects the version from .nvmrc/Dockerfile, runs nvm install/use, checks NPM_TOKEN when a private registry is used, and runs npm install. Use when the user says "set up node", "npm install is failing", "switch node version". Do NOT use for the toolchain check inside TF execution (use /scrapup:forge).
user-invocable: true
---

# Setup Node Environment

Set up the project's Node.js environment: pin the right version via nvm, make sure the private-registry token is available when needed, and install dependencies.

## When to Use

- The user asks to set up or adjust the Node.js environment. /scrapup:forge does **not** invoke this skill: its section 0 runs the simple toolchain check inline
- First setup of a Node.js project
- `npm install` fails with a version or dependency conflict
- The Node.js version needs to change

## When NOT to Use

- Skip when the environment was already set up and validated in the current session.
- Skip when the project does not use Node.js.
- Skip in CI/CD, where the pipeline owns the setup.

## Rules

- **NEVER** use `--legacy-peer-deps` — plain `npm install` must work
- **NEVER** store tokens in skill or project files — `NPM_TOKEN` lives only in the user's shell environment
- **NEVER** request or accept a token value in chat
- **NEVER** switch the Node version without explicit user approval — propose the target version with evidence from the npm output first
- Version conflicts are resolved by updating `.nvmrc` + Dockerfile, never by forcing dependencies

## Scripts

All scripts live in `${CLAUDE_PLUGIN_ROOT}/skills/setup-node-env/`. They take `[project-dir]` as the first argument (default: `.`), except `update-node-version.sh`, which takes `<version> [project-dir]`.

| Script | Purpose | Exit codes |
|--------|---------|------------|
| [`detect-node-version.sh`](detect-node-version.sh) | Detects the version from `.nvmrc` or the Dockerfile | 0=found, 1=no files, 2=Dockerfile without a version |
| [`nvm-install-use.sh`](nvm-install-use.sh) | Loads nvm, then install + use | 0=ok, 1=nvm missing, 2=no .nvmrc, 3=install failed, 4=use failed |
| [`check-npm-token.sh`](check-npm-token.sh) | Checks whether `NPM_TOKEN` is in the environment | 0=available, 1=missing |
| [`npm-install.sh`](npm-install.sh) | Runs `npm install` and classifies the failure | 0=ok, 1=version/deps conflict, 2=other failure |
| [`update-node-version.sh`](update-node-version.sh) `<v>` | Updates `.nvmrc` + Dockerfile, then nvm install/use | 0=ok, 1=version missing/invalid, 2=nothing updated, 3=nvm missing, 4=nvm install/use failed |
| [`docker-build.sh`](docker-build.sh) | BuildKit build of the Dockerfile, `NPM_TOKEN` as a secret | 0=ok, 1=no Dockerfile, 2=secret required but no token, 3=build failed |

## Agent Flow

### 1. Detect the version

```bash
${CLAUDE_PLUGIN_ROOT}/skills/setup-node-env/detect-node-version.sh <project-dir>
```

Decide on the **exit code**. `NODE_VERSION` is printed only on **exit 0**. `DOCKERFILE=<path>` is printed whenever a Dockerfile was found (exit 0 via Dockerfile, or exit 2).

| Exit | Stdout | Agent action |
|------|--------|--------------|
| 0 | `NODE_VERSION=<v>` + `SOURCE=nvmrc` | `.nvmrc` exists — go to step 2 |
| 0 | `DOCKERFILE=<path>` + `NODE_VERSION=<v>` + `SOURCE=dockerfile` | Create `.nvmrc` with `NODE_VERSION` from stdout; go to step 2 |
| 1 | `SOURCE=none` | No `.nvmrc` and no Dockerfile — tell the user and ask for the version |
| 2 | `DOCKERFILE=<path>` + `SOURCE=dockerfile` (no `NODE_VERSION`) | The Dockerfile's Node version cannot be extracted — tell the user and ask for the version. **Never** create `.nvmrc` (there is no version to write) |

### 2. nvm install + use

```bash
${CLAUDE_PLUGIN_ROOT}/skills/setup-node-env/nvm-install-use.sh <project-dir>
```

Exit 0: continue. Any other exit (1 nvm missing, 2 no `.nvmrc`, 3 install failed, 4 use failed): tell the user, include the output, and wait for direction.

### 3. Check NPM_TOKEN (only if the project uses a private registry)

Skip this step when the project installs only public packages (no private registry in `.npmrc` or `package.json` scopes).

```bash
${CLAUDE_PLUGIN_ROOT}/skills/setup-node-env/check-npm-token.sh
```

| Exit | Agent action |
|------|--------------|
| 0 | `NPM_TOKEN` available — go to step 4 |
| 1 | Token missing — ask the user to export `NPM_TOKEN` in their shell; never request or accept the token value in chat |

If the user does not export the token (exit 1): either continue to step 4 knowing private packages will fail, **or** abort with an explicit message. The user decides — never invent or infer a token.

### 4. npm install

```bash
${CLAUDE_PLUGIN_ROOT}/skills/setup-node-env/npm-install.sh <project-dir>
```

Conflict criterion: exit 1 only when the npm error code is `ERESOLVE`, or the install failed with an engine mismatch **error** (`code EBADENGINE`, e.g. with `engine-strict`). `npm WARN EBADENGINE` warnings never count as a conflict.

| Exit | Agent action |
|------|--------------|
| 0 | Success — Node.js is set up |
| 1 | Version conflict — go to step 5 |
| 2 | Other failure (network, registry, auth, permissions) — tell the user, include the output, wait for direction |

### 5. Resolve a version conflict (exit 1 in step 4)

Never resolve a conflict with `--legacy-peer-deps` — update the version and rebuild.

1. **Propose, do not switch.** Propose the target version with evidence from the npm output (the `ERESOLVE`/`EBADENGINE` lines that require it); run `update-node-version.sh` only after explicit user approval. If the user declines, stop and report.
2. After approval, run in order, mapping each exit before moving on:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/setup-node-env/update-node-version.sh <approved-version> <project-dir>
${CLAUDE_PLUGIN_ROOT}/skills/setup-node-env/docker-build.sh <project-dir>
${CLAUDE_PLUGIN_ROOT}/skills/setup-node-env/npm-install.sh <project-dir>
```

`update-node-version.sh`:

| Exit | Agent action |
|------|--------------|
| 0 | Files updated and nvm on the new version — go to `docker-build.sh` |
| 1 | Version missing or invalid (invocation error) — fix the argument and rerun |
| 2 | Nothing updated (no `.nvmrc`, no Dockerfile with `FROM node:<version>`) — tell the user and wait for direction |
| 3 | Files updated but nvm not found — tell the user; do not continue |
| 4 | Files updated but nvm install/use failed — tell the user, include the output |

`docker-build.sh` (requires Docker — check it first with /scrapup:enable-docker-server):

The build uses BuildKit and passes `NPM_TOKEN` as a secret (`--secret id=npm_token,env=NPM_TOKEN`), never as a build-arg, so the token never lands in the image history. A Dockerfile that needs the token must consume it via `RUN --mount=type=secret,id=npm_token ...` (the value is read from `/run/secrets/npm_token`).

| Exit | Agent action |
|------|--------------|
| 0 | Build OK — go to `npm-install.sh` |
| 1 | No Dockerfile — skip the build (non-blocking) and go to `npm-install.sh` |
| 2 | The Dockerfile mounts the `npm_token` secret but `NPM_TOKEN` is not set — back to step 3, then rerun |
| 3 | Build failed — tell the user, include the output, wait for direction |

`npm-install.sh` (second pass): same mapping as step 4. If it exits **1** again (persistent conflict): escalate to the user with the output; do not repeat the cycle automatically. Exit **2**: tell the user and wait for direction.

## Integration with Other Skills

| Skill | Integration |
|-------|-------------|
| /scrapup:forge | **Does not invoke.** Forge's section 0 checks the Node version and installs dependencies inline; this skill handles on-demand environment adjustments |
| /scrapup:enable-docker-server | Make sure Docker is available before [`docker-build.sh`](docker-build.sh) |
