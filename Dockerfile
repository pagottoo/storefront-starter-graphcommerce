# syntax=docker/dockerfile:1.7
# Multi-stage build for GraphCommerce on MageScale platform.
# Hardened for BYO PodSpec: non-root UID 10001, port 3000, read-only rootfs compatible (writes only to /tmp + /app/.next/cache).

ARG NODE_VERSION=20

# ── builder ─────────────────────────────────────────────────────────────────
# No separate deps stage: upstream GraphCommerce gitignores yarn.lock, so `yarn install`
# has to re-resolve every build anyway. One stage keeps the Dockerfile smaller.
FROM node:${NODE_VERSION}-alpine AS builder
WORKDIR /app
RUN apk add --no-cache git python3 make g++ && corepack enable
COPY . .
RUN --mount=type=cache,target=/root/.yarn \
    yarn install

# GC_MAGENTO_ENDPOINT is required at build time for codegen (schema introspection).
# Pass via docker build --build-arg or GitHub Action.
ARG GC_MAGENTO_ENDPOINT=https://configurator.reachdigital.dev/graphql
ARG GC_MAGENTO_VERSION=247
ARG GC_CANONICAL_BASE_URL=https://example.com
ARG GC_HYGRAPH_ENDPOINT=https://eu-central-1.cdn.hygraph.com/content/ckhx7xadya6xs01yxdujt8i80/master
ARG GC_STOREFRONT_0_LOCALE=en
ARG GC_STOREFRONT_0_MAGENTO_STORE_CODE=default
ARG GC_STOREFRONT_0_DEFAULT_LOCALE=true

ENV GC_MAGENTO_ENDPOINT=$GC_MAGENTO_ENDPOINT \
    GC_MAGENTO_VERSION=$GC_MAGENTO_VERSION \
    GC_CANONICAL_BASE_URL=$GC_CANONICAL_BASE_URL \
    GC_HYGRAPH_ENDPOINT=$GC_HYGRAPH_ENDPOINT \
    GC_STOREFRONT_0_LOCALE=$GC_STOREFRONT_0_LOCALE \
    GC_STOREFRONT_0_MAGENTO_STORE_CODE=$GC_STOREFRONT_0_MAGENTO_STORE_CODE \
    GC_STOREFRONT_0_DEFAULT_LOCALE=$GC_STOREFRONT_0_DEFAULT_LOCALE \
    NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1

WORKDIR /app/examples/magento-graphcms
RUN cp graphcommerce.config.ts.example graphcommerce.config.ts && \
    yarn build

# ── runner ──────────────────────────────────────────────────────────────────
FROM node:${NODE_VERSION}-alpine AS runner
WORKDIR /app

RUN apk add --no-cache tini && \
    corepack enable && \
    addgroup -g 10001 -S app && \
    adduser -u 10001 -S app -G app

COPY --from=builder --chown=app:app /app ./
COPY --chown=app:app docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    PORT=3000 \
    HOSTNAME=0.0.0.0

USER 10001
EXPOSE 3000
WORKDIR /app/examples/magento-graphcms

ENTRYPOINT ["/sbin/tini", "--", "/docker-entrypoint.sh"]
CMD ["yarn", "start"]
