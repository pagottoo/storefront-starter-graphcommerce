#!/bin/sh
# Map MageScale platform env vars → GraphCommerce GC_* vars.
# Platform auto-injects MAGENTO_GRAPHQL_URL / MAGENTO_BASE_URL; GraphCommerce reads GC_MAGENTO_ENDPOINT.
set -e

: "${GC_MAGENTO_ENDPOINT:=${MAGENTO_GRAPHQL_URL}}"
: "${GC_CANONICAL_BASE_URL:=${MAGENTO_BASE_URL}}"
export GC_MAGENTO_ENDPOINT GC_CANONICAL_BASE_URL

exec "$@"
