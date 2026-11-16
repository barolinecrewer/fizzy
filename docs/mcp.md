# MCP server

Every account has a [Model Context Protocol](https://modelcontextprotocol.io) endpoint built into the app, so an AI agent can work the boards directly:

```
POST https://your-fizzy.example.com/{account_id}/mcp
Authorization: Bearer <personal access token with read and write permission>
```

It speaks stateless Streamable HTTP, so there is nothing else to run. Create the token under your profile in Fizzy, then add the server to a client, for example Claude Code:

```sh
claude mcp add --transport http fizzy https://your-fizzy.example.com/1234567/mcp \
  --header "Authorization: Bearer fizzy_pat_…"
```

The tools cover boards, cards (create, update, move, assign, comment), nested steps and sections, step templates, and custom fields. They act as the token's owner and reach only what that person can. The definitions live in `app/models/mcp/tools.rb`.

The Paseo plugin in `paseo-plugin/` uses this same endpoint for its board view and attaches it to agents automatically.
