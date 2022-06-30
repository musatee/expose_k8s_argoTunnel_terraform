terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">=3.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">=3.0.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.0.0"
    }
  }
} 