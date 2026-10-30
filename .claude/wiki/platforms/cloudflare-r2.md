# Cloudflare R2 (object storage for uploads)

Status: provider **implemented** in beth-online-shop `00a4328` (`beth-online-shop/backend/src/BethShop.Infrastructure/Storage/R2ImageStorage.cs`);
not exercised against the real service by tests; bucket setup planned for D1.

- Why: PaaS free plans have no persistent disk; R2 is S3-compatible, 10 GB free, no egress fees.
- Access with `AWSSDK.S3` against `https://<accountId>.r2.cloudflarestorage.com`; serve images from the bucket's public
  domain (ideally a separate domain/bucket from the app), `Content-Type: image/webp`, `X-Content-Type-Options: nosniff`.
- Config: `Storage__Provider=R2`, `Storage__R2__AccountId`, `Storage__R2__AccessKeyId`, `Storage__R2__SecretAccessKey`
  (secrets), `Storage__R2__Bucket`, `Storage__R2__PublicBaseUrl`. Scope the API token to the one bucket.
- Pipeline: [image upload pipeline](../features/image-upload-pipeline.md).
