// Smoke test: start the Worker under `wrangler dev` (workerd, the real runtime)
// and drive it through MCP JSON-RPC over HTTP. Run with `npm test`.
// node:http is used because fetch() cannot set the Host header, which the
// MCP handler checks against MCP_HOSTNAME.
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import http from "node:http";

const PORT = 8787;
const HOST = "mcp.example.com"; // must match vars.MCP_HOSTNAME in wrangler.jsonc

// Poll the port until wrangler answers any HTTP request.
function waitForPort(timeoutMs = 90_000) {
  const deadline = Date.now() + timeoutMs;
  return new Promise((resolve, reject) => {
    const attempt = () => {
      const req = http.get({ host: "127.0.0.1", port: PORT, path: "/", headers: { Host: HOST } }, (res) => {
        res.resume();
        resolve();
      });
      req.on("error", () => {
        if (Date.now() > deadline) return reject(new Error("wrangler dev did not start"));
        setTimeout(attempt, 500);
      });
    };
    attempt();
  });
}

async function startWrangler() {
  const proc = spawn(
    "npx",
    ["wrangler", "dev", "--port", String(PORT), "--ip", "127.0.0.1", "--log-level", "error"],
    { stdio: "ignore" },
  );
  await waitForPort();
  return proc;
}

function post(body, { host = HOST, sessionId } = {}) {
  const payload = JSON.stringify(body);
  return new Promise((resolve, reject) => {
    const headers = {
      Host: host,
      "Content-Type": "application/json",
      Accept: "application/json, text/event-stream",
      "Content-Length": Buffer.byteLength(payload),
    };
    if (sessionId) headers["mcp-session-id"] = sessionId;
    const req = http.request(
      { host: "127.0.0.1", port: PORT, path: "/mcp", method: "POST", headers },
      (res) => {
        let text = "";
        res.on("data", (c) => (text += c));
        res.on("end", () => resolve({ status: res.statusCode, headers: res.headers, text }));
      },
    );
    req.on("error", reject);
    req.end(payload);
  });
}

// Responses may be JSON or SSE; extract the JSON-RPC message either way.
function parseRpc({ headers, text }) {
  if (headers["content-type"]?.includes("text/event-stream")) {
    const line = text.split("\n").find((l) => l.startsWith("data:"));
    assert.ok(line, `no SSE data line in: ${text}`);
    return JSON.parse(line.slice(5).trim());
  }
  return JSON.parse(text);
}

const proc = await startWrangler();
let failed = false;
try {
  const init = await post({
    jsonrpc: "2.0",
    id: 1,
    method: "initialize",
    params: {
      protocolVersion: "2025-06-18",
      capabilities: {},
      clientInfo: { name: "smoke", version: "0.0.0" },
    },
  });
  assert.equal(init.status, 200, `initialize status ${init.status}: ${init.text}`);
  const initMsg = parseRpc(init);
  assert.equal(initMsg.result?.serverInfo?.name, "warnetech-mcp", JSON.stringify(initMsg));
  console.log("ok  initialize -> server", initMsg.result.serverInfo.name);

  const listMsg = parseRpc(
    await post({ jsonrpc: "2.0", id: 2, method: "tools/list", params: {} }),
  );
  const names = listMsg.result.tools.map((t) => t.name).sort();
  assert.deepEqual(names, ["echo", "ping"], JSON.stringify(listMsg));
  console.log("ok  tools/list ->", names.join(", "));

  const ping = parseRpc(
    await post({ jsonrpc: "2.0", id: 3, method: "tools/call", params: { name: "ping", arguments: {} } }),
  );
  assert.equal(ping.result.content[0].text, "pong", JSON.stringify(ping));
  console.log("ok  tools/call ping -> pong");

  const echo = parseRpc(
    await post({
      jsonrpc: "2.0",
      id: 4,
      method: "tools/call",
      params: { name: "echo", arguments: { text: "hello phase 2" } },
    }),
  );
  assert.equal(echo.result.content[0].text, "hello phase 2", JSON.stringify(echo));
  console.log("ok  tools/call echo -> round-trips text");

  const foreign = await post(
    { jsonrpc: "2.0", id: 5, method: "tools/list", params: {} },
    { host: "evil.example.org" },
  );
  assert.ok(foreign.status >= 400, `foreign Host should be rejected, got ${foreign.status}`);
  console.log("ok  foreign Host header rejected with", foreign.status);

  console.log("\nAll smoke checks passed.");
} catch (err) {
  failed = true;
  console.error("FAIL", err.message);
} finally {
  proc.kill("SIGTERM");
}
process.exit(failed ? 1 : 0);
