# Changelog

## 0.9.0 - (Unreleased)

## tf-next (0.7.0)

- Adds support for yarn workspaces ([#93](https://github.com/dealmore/terraform-aws-next-js/issues/93), [#107](https://github.com/dealmore/terraform-aws-next-js/pull/107))

### Runtime (1.1.0)

- Bump @vercel/nft from 0.9.5 to 0.10.0 ([#112](https://github.com/dealmore/terraform-aws-next-js/pull/112))

## 0.8.0 - (April 05, 2021)

This release enables Brotli in addition to gzip as default compression method.

**⚠️ Breaking Changes ⚠️**

Before upgrading make sure that you define a new alias `global_region` for the AWS Provider in the `us-east-1` region.
This provider alias is used to create the Lambda@Edge function that must be created in `us-east-1`.

```diff
# main.tf
provider "aws" {
  region = "us-west-2"
}

+ provider "aws" {
+   alias  = "global_region"
+   region = "us-east-1"
+ }

module "tf_next" {
  source = "dealmore/next-js/aws"

+ providers = {
+   aws.global_region = aws.global_region
+ }
}
```

### Terraform module

- Removes internal AWS provider for `us-east-1` region ([#50](https://github.com/dealmore/terraform-aws-next-js/issues/50), [#101](https://github.com/dealmore/terraform-aws-next-js/pull/101))
- Enable Brotli compression for CloudFront ([#8](https://github.com/dealmore/terraform-aws-next-js/issues/8), [#82](https://github.com/dealmore/terraform-aws-next-js/pull/82))
- Adds `cloudfront_geo_restriction` variable ([#97](https://github.com/dealmore/terraform-aws-next-js/pull/97))
- Use `nodejs14.x` as default runtime for Lambda ([#67](https://github.com/dealmore/terraform-aws-next-js/pull/67), [#80](https://github.com/dealmore/terraform-aws-next-js/issues/80), [#81](https://github.com/dealmore/terraform-aws-next-js/pull/81))

### Deploy trigger (0.3.0)

- CloudFront invalidations for static files (e.g. static prerendered HTML or files from `public/`) are only issues if the eTag of the file changes ([#48](https://github.com/dealmore/terraform-aws-next-js/issues/48), [#91](https://github.com/dealmore/terraform-aws-next-js/pull/91))

### tf-next (0.6.1)

- Ensure that `INIT_CWD` environment variable is set to the correct working directory ([#87](https://github.com/dealmore/terraform-aws-next-js/pull/87))

### tf-next (0.6.0)

- Allows dependencies (e.g. Prisma & Blitz.js) to correctly detect the build environment ([#70](https://github.com/dealmore/terraform-aws-next-js/issues/70), [#73](https://github.com/dealmore/terraform-aws-next-js/issues/73), [#85](https://github.com/dealmore/terraform-aws-next-js/pull/85))

## 0.7.4 (April 03, 2021)

### Terraform module

- Use `concat` instead of `merge` for custom CloudFront origins and cache behaviors ([#66](https://github.com/dealmore/terraform-aws-next-js/issues/66), [#105](https://github.com/dealmore/terraform-aws-next-js/pull/105))

## 0.7.3 (March 08, 2021)

### Terraform module

- Bump internal module `terraform-aws-modules/apigateway-v2/aws` from `0.5.0` to `0.11.0` ([#68](https://github.com/dealmore/terraform-aws-next-js/pull/68))
- Bump internal module `dealmore/next-js-image-optimization/aws` from `2.0.0` to `2.0.1` ([#68](https://github.com/dealmore/terraform-aws-next-js/pull/68))

## 0.7.2 (March 04, 2021)

### Terraform module

- Fix for invalid function argument error introduced by `0.7.1` release ([#59](https://github.com/dealmore/terraform-aws-next-js/issues/59))

## 0.7.1 (March 04, 2021)

### Terraform module

- Add option to set the image optimizer version ([#58](https://github.com/dealmore/terraform-aws-next-js/issues/58))

## 0.7.0 (February 13, 2021)

This release brings support for [Next.js image optimization](https://nextjs.org/docs/basic-features/image-optimization) 📸.  
No extra config is needed, simply update the Terraform module and the `tf-next` package to the latest version!  
Check out our example for more information: [Next image component example](https://github.com/dealmore/terraform-aws-next-js/tree/main/examples/next-image)

You can always opt-out from creating resources for image optimization by setting `create_image_optimization = false`.

### Terraform module

- Adds support for `next/image` component ([#28](https://github.com/dealmore/terraform-aws-next-js/issues/28), [#51](https://github.com/dealmore/terraform-aws-next-js/pull/51))
- Refactoring: Outsources a previously private Terraform module, that is now used across multiple projects. Is now avaiable here: [NPM Download Terraform module
  ](https://registry.terraform.io/modules/dealmore/download/npm) ([#41](https://github.com/dealmore/terraform-aws-next-js/issues/41))

### tf-next (0.5.0)

- Adds support for `next/image` component ([#28](https://github.com/dealmore/terraform-aws-next-js/issues/28), [#51](https://github.com/dealmore/terraform-aws-next-js/pull/51))

### Proxy (0.5.0)

- Internal refactoring which changes the way the module is bundled. No feature changes ([#43](https://github.com/dealmore/terraform-aws-next-js/issues/43))

### Deploy trigger (0.2.0)

- Internal refactoring which changes the way the module is bundled. No feature changes ([#43](https://github.com/dealmore/terraform-aws-next-js/issues/43))

## 0.6.2 (January 19, 2021)

### Terraform module

- Bump internal module version of `terraform-aws-modules/lambda/aws`: 1.31.0 -> 1.34.0  
  This should fix an issue when performing a direct upgrade from `v0.3.0` to `v0.6.x`

## 0.6.1 (January 18, 2021)

### Terraform module

- Fix: Correctly propagate the permissions boundary (`lambda_role_permissions_boundary`) to all Lambda & Lambda@Edge functions ([#38](https://github.com/dealmore/terraform-aws-next-js/pull/38))

### tf-next (0.4.1)

- Fix: Request cookie header should be semi-colon delimitated ([#39](https://github.com/dealmore/terraform-aws-next-js/pull/39))

## 0.6.0 (January 16, 2021)

**⚠️ Breaking Changes ⚠️**

You need to update the `tf-next` package to the latest version in order to use it with the `v0.6.0` release.

```sh
npm upgrade tf-next@latest   # npm
yarn upgrade tf-next@latest  # yarn
```

### Terraform module

- Upgrade to API Gateway Payload V2.0 ([#29](https://github.com/dealmore/terraform-aws-next-js/issues/29), [#31](https://github.com/dealmore/terraform-aws-next-js/pull/31))  
  This is only an upgrade of the internally API used by Lambda and API Gateway (Not the resource itself, since we already use API Gateway V2). See this [guide](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-lambda.html) for a detailed look at the differences between the V1.0 and V2.0 format.
  It fixes a bug where no multi-value headers could be sent by a SSR or API page.
- Sends an error message when you try to use the Terraform module together with an old version of `tf-next` ([#5](https://github.com/dealmore/terraform-aws-next-js/issues/5), [#37](https://github.com/dealmore/terraform-aws-next-js/pull/37))
- Upgrades proxy component to `v0.4.0`

### tf-next (0.4.0)

- Adds a version number to the config file, so that the Terraform module is able to warn about a possible version mismatch ([#5](https://github.com/dealmore/terraform-aws-next-js/issues/5), [#37](https://github.com/dealmore/terraform-aws-next-js/pull/37))

### Proxy (0.4.0)

- Fix to handle `resource` handle type properly

## 0.5.3 (January 15, 2021)

### Terraform module

- Fix: Pass permissions boundary to edge proxy lambda ([#35](https://github.com/dealmore/terraform-aws-next-js/pull/35))

## 0.5.2 (January 14, 2021)

### Terraform module

- Adds `tags` variable to set tags on supported AWS resources ([#34](https://github.com/dealmore/terraform-aws-next-js/pull/34))
- Adds `lambda_role_permissions_boundary` variable for setting a permission boundary for the Lambda role ([#33](https://github.com/dealmore/terraform-aws-next-js/pull/33))

## 0.5.1 (January 13, 2021)

### Terraform module

- Adds `cloudfront_hosted_zone_id` output ([#30](https://github.com/dealmore/terraform-aws-next-js/pull/30)).

## 0.5.0 (January 03, 2021)

Happy New Year! 🍾  
With this release we bring native support for [redirects](https://nextjs.org/docs/api-reference/next.config.js/redirects) in Next.js.

### Proxy (0.3.0)

- Adds ability to handle redirects ([#10](https://github.com/dealmore/terraform-aws-next-js/issues/10), [#24](https://github.com/dealmore/terraform-aws-next-js/pull/24)).

### tf-next (0.3.0)

- The build tool got a new name, now it is simply `tf-next` instead of `@dealmore/terraform-next-build`.  
  For backwards compatibility we plan to release new versions to both the old and the new package name until v1.0.

- When running `tf-next build` we now filter out routes with the prefix `_next/static/*` since they are handled directly by CloudFront and will never hit the Proxy.

## 0.4.0 (December 30, 2020)

- Adds [new example](https://github.com/dealmore/terraform-aws-next-js/blob/main/examples/custom-domain) how to use custom domains.

### Terraform module

- Adds ability to change the price class of the associated CloudFront distributions (`cloudfront_price_class`).
- Adds new option after how many days the static assets of previous deployments should be deleted from S3(`expire_static_assets`).
- Updates deploy trigger Lambda function to `v0.1.0`.

### Deploy trigger

- Static routes are now cached much longer by CloudFront.
- Static routes from CloudFront now get invalidated when a new deployment is pushed.
- Updates deploy trigger Lambda function to support expiration of previous deployments.

## 0.3.0 (December 23, 2020)

### Terraform module

- Adds support for Terraform `v0.14`
- Drops support for Terraform `v0.12`

## 0.2.0 (December 22, 2020)

> **Note:** This will be the last release with support for Terraform `v12.x`, see [#18](https://github.com/dealmore/terraform-aws-next-js/issues/18) for more information.

### Terraform module

- Destroy non-empty S3 buckets on stack deletion
- Experimental support for pre-Rendered routes ([#16](https://github.com/dealmore/terraform-aws-next-js/issues/16))

### Terraform Next Build

- Experimental support for pre-Rendered routes ([#16](https://github.com/dealmore/terraform-aws-next-js/issues/16))

### Proxy

- Experimental support for pre-Rendered routes ([#16](https://github.com/dealmore/terraform-aws-next-js/issues/16))
