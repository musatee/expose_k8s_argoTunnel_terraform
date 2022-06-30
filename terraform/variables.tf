variable "tunnel_name" {
  type        = string
  description = "Name of the cloudflare tunnel to be configured for your domain"
}

variable "cloudflare_zone_id" {
  type    = string
  default = "d13abe2e1b404999657c631c00ea14d3"
}