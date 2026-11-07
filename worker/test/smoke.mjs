// Smoke test: drive the bundled Worker through real MCP JSON-RPC requests.
// Run with `npm test` (builds dist/index.js first).
import assert from "node:assert/strict";
import worker from "../dist/index.js";

const HOST = "mcp.example.com";
const env = { MCP_HOSTNAME: HOST };
const ctx = { waitUntil() {}, passThroughOnException() {} };

function rpc(body, { host = HOST, sessionId } = {}) {
  const headers = {
    "Content-Type": "application/json",
    Accept: "application/json, text/event-stream",
  };
  if (sessionId) headers["mcp-session-id"] = sessionId;
  return worker.fetch(
    new Request(`https://${host}/mcp`, {
      method: "POST",
      headers,
      body: JSON.stringify(body),
    }),
    env,
    ctx,
  );
}

// Responses may be JSON or SSE; extract the JSON-RPC message either way.
async function parseRpc(res) {
  const text = await res.text();
  if (res.headers.get("content-type")?.includes("text/event-stream")) {
    const line = text.split("\n").find((l) => l.startsWith("data:"));
    assert.ok(line, `no SSE data line in: ${text}`);
    return JSON.parse(line.slice(5).trim());
  }
  return JSON.parse(text);
}

const init = await rpc({
  jsonrpc: "2.0",
  id: 1,
  method: "initialize",
  params: {
    protocolVersion: "2025-06-18",
    capabilities: {},
    clientInfo: { name: "smoke", version: "0.0.0" },
  },
});
assert.equal(init.status, 200, `initialize status ${init.status}`);
const initMsg = await parseRpc(init);
assert.equal(initMsg.result?.serverInfo?.name, "warnetech-mcp", JSON.stringify(initMsg));
console.log("ok  initialize -> server", initMsg.result.serverInfo.name);

const list = await rpc({ jsonrpc: "2.0", id: 2, method: "tools/list", params: {} });
const listMsg = await parseRpc(list);
const names = listMsg.result.tools.map((t) => t.name).sort();
assert.deepEqual(names, ["echo", "ping"], JSON.stringify(listMsg));
console.log("ok  tools/list ->", names.join(", "));

const ping = await parseRpc(
  await rpc({ jsonrpc: "2.0", id: 3, method: "tools/call", params: { name: "ping", arguments: {} } }),
);
assert.equal(ping.result.content[0].text, "pong", JSON.stringify(ping));
console.log("ok  tools/call ping -> pong");

const echo = await parseRpc(
  await rpc({
    jsonrpc: "2.0",
    id: 4,
    method: "tools/call",
    params: { name: "echo", arguments: { text: "hello phase 2" } },
  }),
);
assert.equal(echo.result.content[0].text, "hello phase 2", JSON.stringify(echo));
console.log("ok  tools/call echo -> round-trips text");

const foreign = await rpc(
  { jsonrpc: "2.0", id: 5, method: "tools/list", params: {} },
  { host: "evil.example.org" },
);
assert.ok(foreign.status >= 400, `foreign Host should be rejected, got ${foreign.status}`);
console.log("ok  foreign Host header rejected with", foreign.status);

console.log("\nAll smoke checks passed.");
