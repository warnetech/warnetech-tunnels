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

## Networks

| Name | ID | Role | Status |
| --- | --- | --- | --- |
| warnetech-tunnel | `86f654bb-aa29-4387-9815-7cb8d258b471` | Public ingress: `www.warnet-tunnel.warnetwork.cloud` -> `localhost:443` | Connected (per logs) |
| warnetech-webserver | `a0c57798-0737-4085-9945-516d3daee4a4` | Tunnel for the web server (cloudflared service) | Not checked |
| warnetech-server | not recorded | Tunnel reaching the private server, host `vpc.warnetwork.cloud` | **Inactive** |
| warnetech-server-vpc | service `019fc1ec-f970-7b93-8cbb-911fa1b4a35f` | Private TCP service, `vpc.warnetwork.cloud`, port 5190 (MySQL) | Blocked until warnetech-server is active |
| debian-core-tunnel | `5513185d-056d-4b7e-806b-516fbd431dcd` | Tunnel, ingress not recorded | Not checked |
| warnetech-server-turn | `9f5a005bac0da51abadf695e3a4dce80` | TURN app (WebRTC relay) | Not checked |
| warnetech-server-sfu | `3c42b7c09db079cb4bfc3cfe14fc23c7` | Serverless SFU app | Not checked |
| warnetech-server-relay | `7e19eafac491292e8d7ada009d629cce` | MoQ relay, endpoint `draft-18.cloudflare.mediaoverquic.com` | Not checked |
| warnetech-server-realtime | `01463559-9e66-49a2-9efd-af212dbaa4eb` | RealtimeKit app | Not checked |

The VPC service is deliberately not bound to the MCP Worker. A bound database on a public endpoint is exposed to every caller of MCP.
