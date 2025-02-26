locals {
  origin_id_static_deployment = "S3 Static Deployment"
}

module "proxy_package" {
  source  = "dealmore/download/npm"
  version = "1.0.0"

  module_name    = "@dealmore/terraform-next-proxy"
  module_version = var.proxy_module_version
  path_to_file   = "dist.zip"
  use_local      = var.debug_use_local_packages
}

##############
# Proxy Config
##############

module "proxy_config" {
  source = "../proxy-config"

  cloudfront_price_class = var.cloudfront_price_class
  proxy_config_json      = var.proxy_config_json
  deployment_name        = var.deployment_name
  tags                   = var.tags

  providers = {
    aws.global_region = aws.global_region
  }
}

#############
# Lambda@Edge
#############

resource "random_id" "function_name" {
  prefix      = "next-tf-proxy-"
  byte_length = 4
}

module "edge_proxy" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "1.34.0"

  lambda_at_edge = true

  function_name             = random_id.function_name.hex
  description               = "Managed by Terraform Next.js"
  handler                   = "handler.handler"
  runtime                   = var.lambda_default_runtime
  role_permissions_boundary = var.lambda_role_permissions_boundary

  create_package         = false
  local_existing_package = module.proxy_package.abs_path

  cloudwatch_logs_retention_in_days = 30

  tags = var.tags

  providers = {
    aws = aws.global_region
  }
}

############
# CloudFront
############

# Managed origin request policy
data "aws_cloudfront_origin_request_policy" "managed_cors_s3_origin" {
  name = "Managed-CORS-S3Origin"
}

# Managed cache policy
data "aws_cloudfront_cache_policy" "managed_caching_optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.deployment_name} - Main"
  price_class         = var.cloudfront_price_class
  aliases             = var.cloudfront_alias_domains
  default_root_object = "index"

  # Static deployment S3 bucket
  origin {
    domain_name = var.static_bucket_endpoint
    origin_id   = local.origin_id_static_deployment

    s3_origin_config {
      origin_access_identity = var.static_bucket_access_identity
    }

    custom_header {
      name  = "x-env-config-endpoint"
      value = "http://${module.proxy_config.config_endpoint}"
    }

    custom_header {
      name  = "x-env-api-endpoint"
      value = var.api_gateway_endpoint
    }
  }

  # Custom origins
  dynamic "origin" {
    for_each = var.cloudfront_origins != null ? var.cloudfront_origins : []
    content {
      domain_name = origin.value["domain_name"]
      origin_id   = origin.value["origin_id"]

      dynamic "s3_origin_config" {
        for_each = lookup(origin.value, "s3_origin_config", null) != null ? [true] : []
        content {
          origin_access_identity = lookup(origin.value["s3_origin_config"], "origin_access_identity", null)
        }
      }

      dynamic "custom_origin_config" {
        for_each = lookup(origin.value, "custom_origin_config", null) != null ? [true] : []

        content {
          http_port                = lookup(origin.value["custom_origin_config"], "http_port", null)
          https_port               = lookup(origin.value["custom_origin_config"], "https_port", null)
          origin_protocol_policy   = lookup(origin.value["custom_origin_config"], "origin_protocol_policy", null)
          origin_ssl_protocols     = lookup(origin.value["custom_origin_config"], "origin_ssl_protocols", null)
          origin_keepalive_timeout = lookup(origin.value["custom_origin_config"], "origin_keepalive_timeout", null)
          origin_read_timeout      = lookup(origin.value["custom_origin_config"], "origin_read_timeout", null)
        }
      }
    }
  }

  # Lambda@Edge Proxy
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.origin_id_static_deployment

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    origin_request_policy_id = var.cloudfront_origin_request_policy_id
    cache_policy_id          = var.cloudfront_cache_policy_id

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = module.edge_proxy.this_lambda_function_qualified_arn
      include_body = false
    }
  }

  # Custom behaviors
  dynamic "ordered_cache_behavior" {
    for_each = var.cloudfront_custom_behaviors != null ? var.cloudfront_custom_behaviors : []
    content {
      path_pattern     = ordered_cache_behavior.value["path_pattern"]
      allowed_methods  = ordered_cache_behavior.value["allowed_methods"]
      cached_methods   = ordered_cache_behavior.value["cached_methods"]
      target_origin_id = ordered_cache_behavior.value["target_origin_id"]

      compress               = ordered_cache_behavior.value["compress"]
      viewer_protocol_policy = ordered_cache_behavior.value["viewer_protocol_policy"]

      origin_request_policy_id = ordered_cache_behavior.value["origin_request_policy_id"]
      cache_policy_id          = ordered_cache_behavior.value["cache_policy_id"]
    }
  }

  # Next.js static assets
  ordered_cache_behavior {
    path_pattern     = "/_next/static/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.origin_id_static_deployment

    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.managed_cors_s3_origin.id
    cache_policy_id          = data.aws_cloudfront_cache_policy.managed_caching_optimized.id
  }

  # Custom error response when a doc is not found in S3 (returns 403)
  # Then shows the 404 page
  custom_error_response {
    error_caching_min_ttl = 60
    error_code            = 403
    response_code         = 404
    response_page_path    = "/404"
  }

  viewer_certificate {
    cloudfront_default_certificate = var.cloudfront_viewer_certificate_arn != null ? false : true
    acm_certificate_arn            = var.cloudfront_viewer_certificate_arn
    ssl_support_method             = var.cloudfront_viewer_certificate_arn != null ? "sni-only" : null
    minimum_protocol_version       = var.cloudfront_viewer_certificate_arn != null ? var.cloudfront_minimum_protocol_version : null
  }

  restrictions {
    dynamic "geo_restriction" {
      for_each = list(var.cloudfront_geo_restriction)
      content {
        restriction_type = geo_restriction.value["restriction_type"]
        locations        = geo_restriction.value["locations"]
      }
    }
  }

  tags = var.tags
}
