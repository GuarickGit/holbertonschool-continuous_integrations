# holbertonschool-continuous_integrations

Building and publishing Docker images in CI with GitHub Actions.

## Application

A small Express app (`server.js`) packaged with a hardened `Dockerfile`:
non-root user, `node:20-alpine` base image and a `HEALTHCHECK` on `/health`.

## Pipeline

The workflow is defined in [`.github/workflows/image.yml`](.github/workflows/image.yml).

| Trigger | Job     | What it does                                                              |
| ------- | ------- | ------------------------------------------------------------------------- |
| `push`  | `build` | Checks out the code, sets up Docker Buildx and builds the image (no push) |

The image is built on a clean GitHub-hosted runner (`ubuntu-latest`), which proves it builds on a machine other than mine.

## Runs

- [Successful build run](https://github.com/GuarickGit/holbertonschool-continuous_integrations/actions/runs/37908902550)
