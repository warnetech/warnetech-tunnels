# warnetech-tunnels

Cloudflare infrastructure as code: a remotely managed tunnel, Zero Trust Access,
and an MCP server on a Worker.

- `infra/` Terraform (Cloudflare provider ~> 5.0)
- `worker/` stateless MCP server (`createMcpHandler`), built with esbuild and tested under `wrangler dev`

## Deploy

```bash
(cd worker && npm ci && npm run build)   # Terraform reads worker/dist/index.js
cd infra
cp terraform.tfvars.example terraform.tfvars   # fill in values; never commit it
terraform init
terraform plan
```

## Adopt the existing tunnel (do this before `apply`)

The live tunnel (`86f654bb-aa29-4387-9815-7cb8d258b471`, ingress
`www.warnet-tunnel.warnetwork.cloud` -> `https://localhost:443`) was created in
the dashboard. Import it so Terraform manages it instead of creating a duplicate:

```bash
cd infra
terraform import cloudflare_zero_trust_tunnel_cloudflared.main <account_id>/86f654bb-aa29-4387-9815-7cb8d258b471
terraform import cloudflare_zero_trust_tunnel_cloudflared_config.main <account_id>/86f654bb-aa29-4387-9815-7cb8d258b471
terraform import 'cloudflare_dns_record.tunnel["www.warnet-tunnel"]' <zone_id>/<existing_dns_record_id>
terraform plan   # review: expect no tunnel replacement
```

Import syntax for each resource is in the provider docs; check the exact ID
format with `terraform import -help` if a command is rejected.

Keep the tunnel token out of the repo and out of chat. Rotate any token that has been pasted.
