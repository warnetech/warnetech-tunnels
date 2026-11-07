# -----------------------------------------------------------------------------
# Phase 2: stateless MCP server on a Worker (see worker/)
#
# Build the bundle before planning:  (cd ../worker && npm ci && npm run build)
# -----------------------------------------------------------------------------

locals {
  mcp_hostname = "${var.mcp_subdomain}.${var.cloudflare_zone}"
  mcp_bundle   = "${path.module}/../worker/dist/index.js"
}

resource "cloudflare_workers_script" "mcp" {
  account_id         = var.cloudflare_account_id
  script_name        = var.mcp_worker_name
  content            = file(local.mcp_bundle)
  main_module        = "index.js"
  compatibility_date = var.mcp_compatibility_date

  # The Agents SDK imports node:async_hooks, which needs nodejs_compat.
  compatibility_flags = ["nodejs_compat"]

  bindings = [
    {
      type = "plain_text"
      name = "MCP_HOSTNAME"
      text = local.mcp_hostname
    },
    {
      type         = "kv_namespace"
      name         = "WARNETECH_KV"
      namespace_id = var.mcp_kv_namespace_id
    },
  ]

  lifecycle {
    precondition {
      condition     = fileexists(local.mcp_bundle)
      error_message = "Worker bundle missing. Run: (cd worker && npm ci && npm run build)"
    }
  }
}

# Serves the Worker on mcp.<zone>. Cloudflare creates the DNS record and certificate.
resource "cloudflare_workers_custom_domain" "mcp" {
  account_id = var.cloudflare_account_id
  hostname   = local.mcp_hostname
  service    = cloudflare_workers_script.mcp.script_name
  zone_id    = var.cloudflare_zone_id
  zone_name  = var.cloudflare_zone
}

# Access gate in front of the MCP endpoint, reusing the account-level policy.
resource "cloudflare_zero_trust_access_application" "mcp" {
  account_id       = var.cloudflare_account_id
  name             = local.mcp_hostname
  domain           = local.mcp_hostname
  type             = "self_hosted"
  session_duration = var.access_session_duration

  policies = [{
    id         = cloudflare_zero_trust_access_policy.allowed_users.id
    precedence = 1
  }]
}
