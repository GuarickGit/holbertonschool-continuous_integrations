# holbertonschool-continuous_integrations

Building and publishing Docker images in CI with GitHub Actions.

## Application

A small Express app (`server.js`) packaged with a hardened `Dockerfile`:
non-root user, `node:20-alpine` base image, a `HEALTHCHECK` on `/health`, and npm removed from the final image (it is only needed to install dependencies).

## Pipeline

The workflow is defined in [`.github/workflows/image.yml`](.github/workflows/image.yml).

| Trigger                  | What it does                                                                                    |
| ------------------------ | ----------------------------------------------------------------------------------------------- |
| `push` (any branch)      | Builds the image, then scans it with Trivy. Nothing is published.                               |
| `push` to `main`         | Same, then logs in to GHCR with `GITHUB_TOKEN` and pushes the image **only if the scan passed** |
| `push` of a Git tag `v*` | Same as `main`, and adds the version tags to the image                                          |

Steps, in order:

1. **Build** the image on the runner without pushing it (`load: true`).
2. **Scan** that image with Trivy. A critical finding fails the job here.
3. **Push** to GHCR, only on `main` and `v*` tags. This build reuses the layers of step 1 through the cache.

The image is built on a clean GitHub-hosted runner (`ubuntu-latest`), which proves it builds on a machine other than mine.

### Authentication

The workflow logs in to GHCR with the temporary `GITHUB_TOKEN` provided by GitHub for each run. The job is granted `packages: write` explicitly. No credential is hardcoded anywhere in the repository.

### Tags

Tags are generated automatically from the Git context by `docker/metadata-action`.

| Tag                      | Generated when               | Meaning                                                             |
| ------------------------ | ---------------------------- | ------------------------------------------------------------------- |
| `main`                   | push to `main`               | Name of the branch the image was built from                         |
| `sha-<short commit SHA>` | every published build        | Immutable: identifies exactly which commit the image was built from |
| `latest`                 | push to the default branch   | Moving tag: always points to the most recent build of `main`        |
| `1.0.0`                  | push of the Git tag `v1.0.0` | Exact release version (the `v` prefix is dropped)                   |
| `1.0`                    | push of the Git tag `v1.0.0` | Tracks the latest patch of the `1.0` line                           |

To publish a new version:

```bash
git tag v1.0.1
git push origin v1.0.1
```

### Layer caching

The build uses the GitHub Actions cache backend (`cache-from: type=gha`, `cache-to: type=gha,mode=max`). Each run starts on a fresh runner, so layers are saved to and restored from this external cache.

Measured on the same commit (`a08112a`), re-running the same workflow:

| Run                                                                                                                    | Cache             | `Build and push Docker image` step | Whole job |
| ---------------------------------------------------------------------------------------------------------------------- | ----------------- | ---------------------------------- | --------- |
| [Attempt 1](https://github.com/GuarickGit/holbertonschool-continuous_integrations/actions/runs/37911123478/attempts/1) | empty (first run) | 12 s                               | 31 s      |
| [Attempt 2](https://github.com/GuarickGit/holbertonschool-continuous_integrations/actions/runs/37911123478/attempts/2) | warm              | 10 s                               | 30 s      |

In attempt 2, the `WORKDIR`, `RUN addgroup`, `COPY package*.json` and `RUN npm install` layers are reported as `CACHED`, and only the final `COPY . .` is executed again.

The gain is small (about 2 s) because this app has a single dependency: restoring layers from the remote cache costs almost as much as rebuilding them. The benefit grows with the number and weight of dependencies.

### Vulnerability scanning policy

Every build is scanned with [Trivy](https://trivy.dev) before anything is published.

| Severity                | Policy                                                                                     |
| ----------------------- | ------------------------------------------------------------------------------------------ |
| `CRITICAL`              | **Blocks the pipeline.** The job fails, the push step is skipped and nothing is published. |
| `HIGH`, `MEDIUM`, `LOW` | Not scanned, so they never block a build.                                                  |

Details:

- A `CRITICAL` finding blocks even when no fix is available yet (`ignore-unfixed` is not set), so that a known critical flaw is never shipped silently.
- The scan covers OS packages and application dependencies, including npm's own bundled packages.
- The Trivy binary is pinned (`v0.69.3`) and the action is pinned to a full commit SHA rather than a tag, because tags of `aquasecurity/trivy-action` were tampered with in March 2026.

**Proof that the scan can fail the build.** The first scan found `CVE-2026-59873` (`CRITICAL`) in `tar` 6.2.1, bundled with npm inside `node:20-alpine`, and stopped the pipeline: [failed run](https://github.com/GuarickGit/holbertonschool-continuous_integrations/actions/runs/37912163497). The application's own dependencies had no finding.

**Fix.** npm is only used to install dependencies at build time, so it is now removed from the final image. The vulnerable package is gone and the image is smaller. The scan then passed and the image was published: [passing run](https://github.com/GuarickGit/holbertonschool-continuous_integrations/actions/runs/37912678657).

Images published before this scan existed (tags `1.0.0` and `1.0`, and earlier `sha-*` tags) were not scanned and contain the vulnerable npm.

## Published image

- Package page: [ghcr.io/guarickgit/holbertonschool-continuous_integrations](https://github.com/GuarickGit/holbertonschool-continuous_integrations/pkgs/container/holbertonschool-continuous_integrations)

```bash
docker pull ghcr.io/guarickgit/holbertonschool-continuous_integrations:latest
```

## Runs

- [Build only (task 0)](https://github.com/GuarickGit/holbertonschool-continuous_integrations/actions/runs/37908902550)
- [Build and publish to GHCR (task 1)](https://github.com/GuarickGit/holbertonschool-continuous_integrations/actions/runs/37909300548)
- [Branch tags from the Git context (task 2)](https://github.com/GuarickGit/holbertonschool-continuous_integrations/actions/runs/37909973162)
- [Version tags from the Git tag `v1.0.0` (task 2)](https://github.com/GuarickGit/holbertonschool-continuous_integrations/actions/runs/37910209001)
- [Layer cache, attempt 1: before (task 3)](https://github.com/GuarickGit/holbertonschool-continuous_integrations/actions/runs/37911123478/attempts/1)
- [Layer cache, attempt 2: after (task 3)](https://github.com/GuarickGit/holbertonschool-continuous_integrations/actions/runs/37911123478/attempts/2)
- [Scan fails on a critical finding, nothing published (task 4)](https://github.com/GuarickGit/holbertonschool-continuous_integrations/actions/runs/37912163497)
- [Scan passes after the fix, image published (task 4)](https://github.com/GuarickGit/holbertonschool-continuous_integrations/actions/runs/37912678657)
