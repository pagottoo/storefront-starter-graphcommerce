import type { GraphCommerceConfig } from '@graphcommerce/next-config'

/**
 * MageScale default config — single-storefront starter.
 *
 * All fields below are overridable at build time via GC_* env vars
 * (see .github/workflows/magescale-deploy.yml). This file just gives
 * the build a valid shape so codegen can run; real values come from
 * Repository Variables.
 */
const config: Partial<GraphCommerceConfig> = {
  robotsAllow: false,
  limitSsg: true,
  hygraphEndpoint: 'https://eu-central-1.cdn.hygraph.com/content/ckhx7xadya6xs01yxdujt8i80/master',
  magentoEndpoint: 'https://configurator.reachdigital.dev/graphql',
  magentoVersion: 247,
  canonicalBaseUrl: 'https://example.com',
  storefront: [
    {
      locale: 'en',
      magentoStoreCode: 'default',
      defaultLocale: true,
    },
  ],
  productFiltersPro: true,
  productFiltersLayout: 'DEFAULT',
}

export default config
