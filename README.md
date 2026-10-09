# holbertonschool-continuous_integrations

Building and publishing Docker images in CI with GitHub Actions.

## Application

A small Express app (`server.js`) packaged with a hardened `Dockerfile`:
non-root user, `node:20-alpine` base image and a `HEALTHCHECK` on `/health`.

## Pipeline

The workflow is defined in [`.github/workflows/image.yml`](.github/workflows/image.yml).

| Trigger             | Job     | What it does                                                                |
| ------------------- | ------- | --------------------------------------------------------------------------- |
| `push` (any branch) | `build` | Checks out the code, sets up Docker Buildx and builds the image             |
| `push` to `main`    | `build` | Also logs in to GHCR with `GITHUB_TOKEN` and pushes the image with its tags |

The image is built on a clean GitHub-hosted runner (`ubuntu-latest`), which proves it builds on a machine other than mine.

### Authentication

The workflow logs in to GHCR with the temporary `GITHUB_TOKEN` provided by GitHub for each run. The job is granted `packages: write` explicitly. No credential is hardcoded anywhere in the repository.

### Tags

| Tag                      | Meaning                                                             |
| ------------------------ | ------------------------------------------------------------------- |
| `sha-<short commit SHA>` | Immutable: identifies exactly which commit the image was built from |
| `latest`                 | Moving tag: always points to the most recent build of `main`        |

## Published image

- Package page: [ghcr.io/guarickgit/holbertonschool-continuous_integrations](https://github.com/GuarickGit/holbertonschool-continuous_integrations/pkgs/container/holbertonschool-continuous_integrations)

```bash
docker pull ghcr.io/guarickgit/holbertonschool-continuous_integrations:latest
```

## Runs

- [Build only (task 0)](https://github.com/GuarickGit/holbertonschool-continuous_integrations/actions/runs/37908902550)
- [Build and publish to GHCR (task 1)](https://github.com/GuarickGit/holbertonschool-continuous_integrations/actions/runs/37909300548)
