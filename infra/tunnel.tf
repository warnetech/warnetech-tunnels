# -----------------------------------------------------------------------------
# Cloudflare Tunnel (remotely-managed)
# -----------------------------------------------------------------------------

resource "cloudflare_zero_trust_tunnel_cloudflared" "main" {
  account_id = var.cloudflare_account_id
  name       = var.tunnel_name
  config_src = "cloudflare"
}

# Tunnel token — used to run cloudflared on the origin server
data "cloudflare_zero_trust_tunnel_cloudflared_token" "main" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.main.id
}

# -----------------------------------------------------------------------------
# Tunnel ingress configuration
# -----------------------------------------------------------------------------

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "main" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.main.id

  config = {
    ingress = concat(
      [for subdomain, svc in var.tunnel_services : {
        hostname = "${subdomain}.${var.cloudflare_zone}"
        service  = svc.service
      }],
      [{ service = "http_status:404" }]
    )
  }
}

# -----------------------------------------------------------------------------
# DNS records — CNAME each subdomain to the tunnel
# -----------------------------------------------------------------------------

resource "cloudflare_dns_record" "tunnel" {
  for_each = var.tunnel_services

  zone_id = var.cloudflare_zone_id
  name    = each.key
  content = "${cloudflare_zero_trust_tunnel_cloudflared.main.id}.cfargotunnel.com"
  type    = "CNAME"
  ttl     = 1
  proxied = true
}
