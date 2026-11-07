# -----------------------------------------------------------------------------
# Cloudflare account & zone
# -----------------------------------------------------------------------------

variable "cloudflare_api_token" {
  description = "Scoped API token with Zone:DNS:Edit, Access:Apps:Edit, Tunnel:Edit"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID (found in dashboard URL)"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Zone ID for the domain to attach tunnels to"
  type        = string
}

variable "cloudflare_zone" {
  description = "Domain name (e.g. example.com)"
  type        = string
}

# -----------------------------------------------------------------------------
# Tunnel configuration
# -----------------------------------------------------------------------------

variable "tunnel_name" {
  description = "Human-readable tunnel name"
  type        = string
  default     = "warnetech-tunnel"
}

variable "tunnel_services" {
  description = "Map of subdomain prefix -> origin service URL"
  type = map(object({
    service = string
  }))
  default = {
    app = { service = "http://localhost:8080" }
  }
}

# -----------------------------------------------------------------------------
# Access configuration
# -----------------------------------------------------------------------------

variable "access_allowed_emails" {
  description = "Email addresses allowed through Access gate"
  type        = list(string)
}

variable "access_allowed_email_domains" {
  description = "Email domains allowed through Access gate (e.g. example.com)"
  type        = list(string)
  default     = []
}

variable "access_session_duration" {
  description = "Access session duration (e.g. 24h, 720h)"
  type        = string
  default     = "24h"
}
