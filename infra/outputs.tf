# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "tunnel_id" {
  description = "Cloudflare Tunnel ID"
  value       = cloudflare_zero_trust_tunnel_cloudflared.main.id
}

output "tunnel_token" {
  description = "Token to run cloudflared on the origin (use: cloudflared tunnel run --token <token>)"
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.main.token
  sensitive   = true
}

output "tunnel_cname" {
  description = "Tunnel CNAME target"
  value       = "${cloudflare_zero_trust_tunnel_cloudflared.main.id}.cfargotunnel.com"
}

output "service_urls" {
  description = "Public URLs for each tunnel service"
  value = {
    for subdomain, _ in var.tunnel_services :
    subdomain => "https://${subdomain}.${var.cloudflare_zone}"
  }
}

output "mcp_url" {
  description = "Public MCP endpoint (behind Access)"
  value       = "https://${local.mcp_hostname}/mcp"
}

output "cloudflared_run_command" {
  description = "Command to start cloudflared on the origin server"
  value       = "cloudflared tunnel run --token $(terraform output -raw tunnel_token)"
}
