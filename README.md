# holbertonschool-continuous_integrations

Building and publishing Docker images in CI with GitHub Actions.

## Application

A small Express app (`server.js`) packaged with a hardened `Dockerfile`:
non-root user, `node:20-alpine` base image and a `HEALTHCHECK` on `/health`.

## Pipeline

The workflow is defined in [`.github/workflows/image.yml`](.github/workflows/image.yml).

| Trigger                  | Job     | What it does                                                                |
| ------------------------ | ------- | --------------------------------------------------------------------------- |
| `push` (any branch)      | `build` | Checks out the code, sets up Docker Buildx and builds the image             |
| `push` to `main`         | `build` | Also logs in to GHCR with `GITHUB_TOKEN` and pushes the image with its tags |
| `push` of a Git tag `v*` | `build` | Same as above, and adds the version tags to the image                       |

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
