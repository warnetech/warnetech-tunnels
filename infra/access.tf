# -----------------------------------------------------------------------------
# Reusable Access policy — who can authenticate
# -----------------------------------------------------------------------------

resource "cloudflare_zero_trust_access_policy" "allowed_users" {
  account_id = var.cloudflare_account_id
  name       = "${var.tunnel_name}-allowed-users"
  decision   = "allow"

  include = concat(
    [for email in var.access_allowed_emails : {
      email = { email = email }
    }],
    [for domain in var.access_allowed_email_domains : {
      email_domain = { domain = domain }
    }]
  )
}

# -----------------------------------------------------------------------------
# Access application per tunnel service
# -----------------------------------------------------------------------------

resource "cloudflare_zero_trust_access_application" "service" {
  for_each = var.tunnel_services

  account_id          = var.cloudflare_account_id
  name                = "${each.key}.${var.cloudflare_zone}"
  domain              = "${each.key}.${var.cloudflare_zone}"
  type                = "self_hosted"
  session_duration    = var.access_session_duration

  policies = [{
    id         = cloudflare_zero_trust_access_policy.allowed_users.id
    precedence = 1
  }]
}
