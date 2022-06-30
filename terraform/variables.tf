variable "tunnel_name" {
  type        = string
  description = "Name of the cloudflare tunnel to be configured for your domain"
}

variable "cloudflare_zone_id" {
  type    = string
  default = "d13abe2e1b404999657c631c00ea14d3"
}

variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "cluster_name" {
  type    = string
  default = "kaz"
}

variable "aws_access_key" {
  type        = string
  description = "Enter AWS_ACCESS_KEY_ID of your named profile used in configuration"
}

variable "aws_secret_key" {
  type        = string
  description = "Enter AWS_SECRET_ACCESS_KEY of your named profile used in configuration"
}