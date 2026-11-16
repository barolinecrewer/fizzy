import type { PluginServerContext } from "@getpaseo/plugin/server";
import { authorization, callFizzy, mcpUrl } from "./server/fizzy";
import { callTool, connection } from "./shared/fizzy";

export default function contribute(server: PluginServerContext) {
  const settings = server.registerSettings(connection);

  async function current() {
    const state = await settings.read();
    if (state.status !== "ready") throw new Error(`Fizzy settings are invalid: ${state.error}`);
    return state.values;
  }

  server.handle(callTool, async ({ tool, arguments: args }) => ({ data: await callFizzy(await current(), tool, args) }));

  // Agents get the same tools the board uses, straight from Fizzy's own MCP endpoint.
  server.addHook("agent.open.before", async ({ request }) => {
    const values = await current().catch(() => null);
    if (!values?.attachToAgents || !values.url.trim() || !values.token.trim()) return request;

    return {
      ...request,
      mcpServers: { ...request.mcpServers, fizzy: { type: "http", url: mcpUrl(values), headers: authorization(values) } },
    };
  });

  return () => {};
}
