# syntax=docker/dockerfile:1.7
# Standalone build for the magento-graphcms example — mirrors upstream's
# periodic-build.yml strategy: extract the example app from the monorepo and
# install it as if it were a plain Next.js project. Avoids yarn workspaces,
# husky prepare, and monorepo postinstall gymnastics. Debian base (glibc) has
# broader native-module prebuilt coverage than alpine (musl).

ARG NODE_VERSION=20

# ── builder ─────────────────────────────────────────────────────────────────
FROM node:${NODE_VERSION}-bookworm-slim AS builder
WORKDIR /build

RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3 make g++ ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY examples/magento-graphcms/ /build/
# MageScale-specific single-storefront config (overrides upstream .example
# which ships a 2-storefront config that requires nl_NL store view).
COPY graphcommerce.config.magescale.ts /build/graphcommerce.config.ts

RUN corepack enable

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

RUN yarn install && yarn build

# ── runner ──────────────────────────────────────────────────────────────────
FROM node:${NODE_VERSION}-bookworm-slim AS runner
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends tini ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && corepack enable \
    && groupadd -g 10001 app \
    && useradd -u 10001 -g app -s /sbin/nologin -M app

COPY --from=builder --chown=app:app /build ./
COPY --chown=app:app docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    PORT=3000 \
    HOSTNAME=0.0.0.0

USER 10001
EXPOSE 3000

ENTRYPOINT ["/usr/bin/tini", "--", "/docker-entrypoint.sh"]
CMD ["yarn", "start"]
