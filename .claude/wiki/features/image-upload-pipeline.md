# Image upload pipeline (SkiaSharp, EXIF, storage abstraction)

Status: **implemented** — beth-online-shop `00a4328` (B1). cafe-pos-system has a simpler item-photo upload
(`cafe-pos-system/backend/src/CafePos.Api/Http/Uploads.cs`, `cafe-pos-system/backend/src/CafePos.Application/Common/Uploads/`).

## What it does
- Admin-only upload, max 5 MB; type by **magic bytes** only (JPEG/PNG/WebP), never the client `Content-Type`.
- Reads header dimensions (`SKCodec.Info`) and refuses > 6000×6000 **before** decoding (decompression bombs).
- Applies the EXIF orientation to the pixels (Skia's decode ignores it), then re-encodes to WebP at 400 and 1600 px with
  all metadata removed (strips GPS, kills polyglots).
- Random storage key (never the user filename); `IImageStorage` with `Local` (served at `/media/{key}`) and `R2`
  (S3 API) providers; served with `Content-Type: image/webp` + `X-Content-Type-Options: nosniff`.

## Reference implementation
- `beth-online-shop/backend/src/BethShop.Infrastructure/Storage/SkiaImageProcessor.cs`,
  `beth-online-shop/backend/src/BethShop.Infrastructure/Storage/LocalImageStorage.cs`,
  `beth-online-shop/backend/src/BethShop.Infrastructure/Storage/R2ImageStorage.cs`,
  `beth-online-shop/backend/src/BethShop.Infrastructure/Storage/StorageOptions.cs`,
  `beth-online-shop/backend/src/BethShop.Application/Features/Catalog/Images.cs`,
  `beth-online-shop/backend/src/BethShop.Application/Features/Catalog/ProductImageService.cs`.
- Tests: `beth-online-shop/backend/tests/BethShop.Api.IntegrationTests/ImagePipelineTests.cs` (oversize, bad magic bytes,
  EXIF orientation via an injected Orientation tag, bomb), `beth-online-shop/backend/tests/BethShop.Api.IntegrationTests/ProductImageTests.cs`,
  `beth-online-shop/backend/tests/BethShop.Api.IntegrationTests/DevSeedAndStorageTests.cs`.
- Frontend URL helper: `beth-online-shop/frontend/src/lib/assetUrl.ts` (uncommitted at `00a4328`; check it exists).

## Config
`Storage__Provider` (`Local` default in Development, required elsewhere), `Storage__Local__RootPath`,
`Storage__R2__AccountId/AccessKeyId/SecretAccessKey/Bucket/PublicBaseUrl` ([Cloudflare R2](../platforms/cloudflare-r2.md)).

## Port
Copy the `Storage/` folder, `Images.cs`, the service and `ImagePipelineTests`; packages `SkiaSharp` +
`SkiaSharp.NativeAssets.Linux.NoDependencies` (no extra OS packages in the Linux image) and `AWSSDK.S3`.

## Gotchas
- Use SkiaSharp (MIT). ImageSharp 3+ is under the Six Labors Split License (paid above US$1M revenue; v4 needs a licence
  file at build time) — check any library's licence before recommending it.
- `Local` storage is lost on redeploy without a persistent disk; a Vite dev server must proxy `/media` as well as `/api`.
- Test orientation with a JPEG carrying an injected EXIF Orientation tag, or portraits ship sideways.
