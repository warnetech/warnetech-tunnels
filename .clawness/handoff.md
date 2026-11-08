**Autostart:** yes

# Handoff: NextDNS to Cloudflare (option 2)

## Goal
Route home/LAN DNS through the Cloudflare tunnel setup, with NextDNS filtering as the upstream. Chosen option: NextDNS upstream behind cloudflared.

## Facts gathered
- NextDNS profile: `e96e52`
  - DoT: `e96e52.dns.nextdns.io`
  - DoH: `https://dns.nextdns.io/e96e52`
  - Legacy DNS servers: `45.90.28.207`, `45.90.30.207`
  - Linked IP currently `49.186.173.239` (home network only; not for mobile)
- Repo `warnetech/warnetech-tunnels` (branch `claude/new-session-vx2rvj`) is Terraform for Cloudflare Tunnel, Zero Trust Access, DNS, and an MCP Worker. `NextDNS` is not referenced anywhere in it.
- Live tunnel: `warnetech-tunnel` (`86f654bb-aa29-4387-9815-7cb8d258b471`), ingress `www.warnet-tunnel.warnetwork.cloud` -> `https://localhost:443`.
- Cloudflare MCP connector is NOT authorized in this session. Needs sign-in in claude.ai connector settings.

## Steps
1. **Verify cloudflared DNS support.** Confirm with current official Cloudflare docs whether `cloudflared` can proxy DNS to an upstream DoH endpoint (e.g. `https://dns.nextdns.io/e96e52`). Note the status of any deprecated `proxy-dns` mode. Cite the URL. Do not assume.
2. **Locate the home server's `cloudflared` setup.** Needs the user: OS, how `cloudflared` runs (service or container), current config, and which device/LAN uses that server as resolver. Ask if not known. No access from this session.
3. **Make the change in the repo** only after 1 and 2 are settled. Likely Terraform or config files, plus a verification plan (`dig` against the proxy, and a test lookup that NextDNS blocks). Do not commit or push unless asked.

## Constraints
- Never put the tunnel token or API token in the repo or in chat. `terraform.tfvars` stays uncommitted.
- Mobile Linked IP is not recommended by NextDNS; do not rely on it for phones.
- Tests: any new logic needs a test (ENF-TEST-001). Verify with real command output before claiming done (ENF-VERIFY-001).

## Next step
Run Step 1: search current Cloudflare docs for `cloudflared` DNS proxy / upstream DoH support, then report findings and ask the user for Step 2 details.
