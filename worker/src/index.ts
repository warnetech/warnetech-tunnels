import { McpServer } from "@modelcontextprotocol/server";
import { createMcpHandler } from "agents/mcp/server";
import { z } from "zod";

interface McpEnv {
  // Public hostname this Worker is served on (set by Terraform as a plain_text binding).
  // The MCP handler rejects Host headers that are not in its allowlist.
  MCP_HOSTNAME: string;
}

function createServer(): McpServer {
  const server = new McpServer({ name: "warnetech-mcp", version: "0.1.0" });

  server.registerTool(
    "ping",
    { description: "Health check. Returns 'pong'." },
    async () => ({
      content: [{ type: "text", text: "pong" }],
    }),
  );

  server.registerTool(
    "echo",
    {
      description: "Echo the given text back unchanged.",
      inputSchema: z.object({ text: z.string().max(2000) }),
    },
    async ({ text }) => ({
      content: [{ type: "text", text }],
    }),
  );

  return server;
}

export default {
  fetch(request: Request, env: McpEnv, ctx: ExecutionContext): Promise<Response> {
    const handler = createMcpHandler(createServer, {
      allowedHostnames: [env.MCP_HOSTNAME],
    });
    return handler(request, env, ctx);
  },
} satisfies ExportedHandler<McpEnv>;
