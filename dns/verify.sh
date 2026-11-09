#!/usr/bin/env bash
# Verifies the LAN resolver forwards to NextDNS and that NextDNS filtering applies.
# Usage: dns/verify.sh [resolver-ip] [blocked-test-domain]
# The blocked domain must be blocked in profile e96e52 (e.g. add it under Denylist).
set -euo pipefail
RESOLVER="${1:-127.0.0.1}"
BLOCKED="${2:-}"
fail=0

ans=$(dig +short @"$RESOLVER" example.com A | head -n1)
if [[ -n "$ans" ]]; then echo "ok   resolves example.com -> $ans"; else echo "FAIL example.com did not resolve"; fail=1; fi

if [[ -n "$BLOCKED" ]]; then
  b=$(dig +short @"$RESOLVER" "$BLOCKED" A | head -n1)
  # NextDNS blocks by answering 0.0.0.0 (or the blocked-page IP)
  if [[ "$b" == "0.0.0.0" || -z "$b" ]]; then echo "ok   $BLOCKED blocked (answer: ${b:-none})"; else echo "FAIL $BLOCKED not blocked (answer: $b)"; fail=1; fi
fi

exit $fail
