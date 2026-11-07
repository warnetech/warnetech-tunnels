Phase 2 MCP Worker and network inventory are done and pushed (branch claude/peaceful-lamport-j6hdpv, HEAD 00e4b3d). Worker smoke tests pass; terraform validate passes.

Next: deploy the MCP Worker, then repoint the MCP portal. Repo: cd worker && npm ci && npm run build; then in infra/ run terraform apply -target=cloudflare_workers_script.mcp -target=cloudflare_workers_custom_domain.mcp -target=cloudflare_zero_trust_access_application.mcp. Portal: dashboard MCP Portals > warnetech-server-mcp > Basic info, set HTTP URL to https://mcp.warnetwork.cloud/mcp, then Authenticate server.

Uncommitted: none.

Open questions:
- Did the user mean "pass" as the Access/OAuth login for the portal, or a deploy readiness check? Unanswered.
- Tunnel import still needs zone ID and DNS record ID from the user.
- Tokens shown in chat are compromised: GitHub ghp_ tokens, cfut_ AI gateway token, RealtimeKit/TURN API tokens, Access enterprise link, tunnel tokens. User must rotate.
- MCP hostname confirmed by user? Last answer was "confirmed" without a choice; apex vs mcp. unresolved, default mcp.warnetwork.cloud.
- Remaining network: warnetech-server-vpc (019fc1ec) TCP 5190 status to confirm.

Autostart: yes
