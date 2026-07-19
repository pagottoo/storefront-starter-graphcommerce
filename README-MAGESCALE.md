# MageScale storefront starter — GraphCommerce

BYO storefront template for the [MageScale](https://magescale.cloud) platform, built on top of [GraphCommerce](https://www.graphcommerce.org/) (Next.js 16 + React 19 + Magento GraphQL).

This is a fork of `graphcommerce-org/graphcommerce` with three additions:

| File | Purpose |
|---|---|
| `Dockerfile` | Multi-stage build, hardened for MageScale BYO PodSpec (non-root UID 10001, port 3000). |
| `docker-entrypoint.sh` | Maps platform-injected `MAGENTO_GRAPHQL_URL` → GraphCommerce `GC_MAGENTO_ENDPOINT` at container start. |
| `.github/workflows/magescale-deploy.yml` | Build → push to Docker Hub → POST deploy webhook. |

## Quick start

1. **Use this template** — click "Use this template" on GitHub, or fork.
2. **Configure your storefront** — edit `examples/magento-graphcms/graphcommerce.config.ts` (copy from `.example`).
3. **Set GitHub Actions vars** (Settings → Secrets and variables → Actions):
   - **Variables** (build-time, non-secret): `GC_MAGENTO_ENDPOINT`, `GC_MAGENTO_VERSION`, `GC_CANONICAL_BASE_URL`, `GC_HYGRAPH_ENDPOINT`, `GC_STOREFRONT_0_LOCALE`, `GC_STOREFRONT_0_MAGENTO_STORE_CODE`
   - **Variables (optional)**: `DOCKERHUB_IMAGE` — override image name (default: `<DOCKERHUB_USERNAME>/storefront-starter-graphcommerce`)
   - **Secrets**: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` (Docker Hub PAT with Read/Write on the repo), `MAGESCALE_WEBHOOK_URL`, `MAGESCALE_WEBHOOK_TOKEN` (from Console → Environment → Components → Storefront → Deploy)
4. **Push to `main`** — the workflow builds, publishes to `docker.io/<DOCKERHUB_USERNAME>/storefront-starter-graphcommerce`, and calls the MageScale webhook to trigger deploy.
5. **Set your registry auth in MageScale Console** — only needed if you keep the image private on Docker Hub. Console → Environment → Storefront → Container image → Registry auth (Docker Hub username + PAT with `Public Repo Read` or `Read`).

## Env var flow

```
GitHub Actions vars ─┐
                     ├─► docker build --build-arg GC_* ─► image
                     │   (used for codegen at build time)
                     │
MageScale Console ───┴─► envFrom Secret at runtime
Storefront → Env vars     (client scope, e.g. GC_GOOGLE_ANALYTICS_ID)
                     │
MageScale platform ──┴─► auto-injected: MAGENTO_BASE_URL, MAGENTO_GRAPHQL_URL,
                          MAGENTO_REST_URL, PORT
                          (mapped to GC_* by docker-entrypoint.sh)
```

## PodSpec requirements

If MageScale enforces `readOnlyRootFilesystem: true`, mount an `emptyDir` at `/app/.next/cache` — Next.js writes ISR cache there and will crash on read-only FS.

## Local dev

Follow the upstream [GraphCommerce docs](https://www.graphcommerce.org/docs/framework/getting-started). This starter's only additions live at the repo root — nothing in `examples/magento-graphcms/` diverges from upstream.

## Updating from upstream

```sh
git remote add upstream https://github.com/graphcommerce-org/graphcommerce.git
git fetch upstream
git merge upstream/main   # or upstream/canary
```

Only the three files listed above are MageScale-specific — merges rarely conflict.
