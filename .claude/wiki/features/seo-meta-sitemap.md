# SEO meta injection for SPA links + sitemap.xml + robots.txt

Status: **implemented** — beth-online-shop `00a4328` (B1).

## What it does
Link previews (Facebook, Messenger) don't run JavaScript, and SSR would need a Node server. Instead the API's SPA
fallback rewrites `index.html` for `/p/{slug}` (product) and `/c/{slug}` (category): unique `<title>`, description,
canonical and `og:*` tags (404 status for unknown slugs). `GET /sitemap.xml` and `GET /robots.txt` are served by the API
from the catalog.

## Reference implementation
- `beth-online-shop/backend/src/BethShop.Api/Http/SpaMeta.cs` (`RenderAsync(ctx, indexHtml, ct)` → `(Html, Status)`),
  `beth-online-shop/backend/src/BethShop.Api/Http/SpaHosting.cs`, `beth-online-shop/backend/src/BethShop.Api/Http/SiteUrls.cs`,
  `beth-online-shop/backend/src/BethShop.Api/Controllers/SeoController.cs`.
- Tests: `beth-online-shop/backend/tests/BethShop.Api.IntegrationTests/SeoTests.cs`,
  `beth-online-shop/backend/tests/BethShop.Api.IntegrationTests/SpaHostingTests.cs`.

## Config
`Spa__RootPath`, `Seo__PublicBaseUrl` (public origin for sitemap/canonical/`og:` URLs; defaults to the request origin,
so set it in production).

## Port
Requires [same-origin single-image deploy](same-origin-single-image-deploy.md). Copy `SpaMeta`, `SiteUrls`,
`SeoController` and the tests; map your public routes to entity lookups. HTML-encode every injected value.
For a static site use Astro's per-page meta + `@astrojs/sitemap` instead.
