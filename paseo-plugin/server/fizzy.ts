export interface Connection {
  url: string;
  token: string;
}

export function mcpUrl({ url }: Connection): string {
  return `${url.trim().replace(/\/+$/, "")}/mcp`;
}

export function authorization({ token }: Connection): Record<string, string> {
  return { Authorization: `Bearer ${token.trim()}` };
}

export async function callFizzy(connection: Connection, tool: string, args: Record<string, unknown>): Promise<unknown> {
  if (!connection.url.trim() || !connection.token.trim()) {
    throw new Error("Set the Fizzy URL and access token in the plugin's settings.");
  }

  const response = await fetch(mcpUrl(connection), {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "application/json", ...authorization(connection) },
    body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: tool, arguments: args } }),
  });
  if (response.status === 401) throw new Error("Fizzy refused the access token. It must be a read and write token.");
  if (!response.ok) throw new Error(`Fizzy answered ${response.status}. Check the account URL.`);

  const { result, error } = (await response.json()) as {
    result?: { content: { text: string }[]; isError: boolean };
    error?: { message: string };
  };
  if (!result) throw new Error(error?.message ?? "Fizzy sent no result.");
  if (result.isError) throw new Error(result.content[0].text);
  return JSON.parse(result.content[0].text);
}
