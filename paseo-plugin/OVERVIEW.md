# Fizzy

Shows your Fizzy boards inside Paseo and lets you work them without leaving it. Open Fizzy from the sidebar, the Command Center, or as a workspace panel beside your agents.

On a board you can add cards to any column and open a card to move it, tick off steps, add steps and sub-steps, apply a step template, fill in custom fields, assign people, and comment. The board refreshes every 20 seconds.

Agents opened on this host also get Fizzy's MCP tools, so they can read and update the same cards. Turn that off in the plugin's settings.

## Setup

This plugin talks to a Fizzy that has the MCP endpoint at `/{account}/mcp`. In the plugin's settings enter:

- Account URL: your Fizzy address including the account number, such as `https://fizzy.example.com/1234567`.
- Access token: a read and write personal access token, created in Fizzy under your profile.

## What it reads and sends

Every action is a call from the Paseo daemon to your Fizzy's MCP endpoint, authenticated with the access token. Nothing goes anywhere else. The token is saved in this plugin's host settings as plain JSON, readable by Paseo clients connected to the host.
