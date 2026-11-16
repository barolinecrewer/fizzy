import { defineRpc, defineSettings } from "@getpaseo/plugin";
import { z } from "zod";

export const connection = defineSettings({
  id: "connection",
  scope: "host",
  version: 1,
  schema: z.object({
    // The account URL, slug included: https://fizzy.example.com/1234567
    url: z.string().default(""),
    token: z.string().default(""),
    attachToAgents: z.boolean().default(true),
  }),
});

// Every board action is one of Fizzy's MCP tools, so the plugin and agents share one API.
export const callTool = defineRpc({
  name: "fizzy.call",
  input: z.object({ tool: z.string(), arguments: z.record(z.string(), z.unknown()) }),
  output: z.object({ data: z.unknown() }),
});

export interface Named {
  id: string;
  name: string;
}

export interface Field extends Named {
  kind: "text" | "number" | "date" | "select";
  options: string[];
  value?: string | null;
}

export interface Board extends Named {
  columns: Named[];
  custom_fields: Field[];
  users: Named[];
}

export interface Step {
  id: string;
  content: string;
  section: boolean;
  completed: boolean;
  assignee: string | null;
  steps: Step[];
}

export interface Card {
  number: number;
  title: string;
  column_id: string | null;
  closed: boolean;
  not_now: boolean;
  assignees: string[];
  tags: string[];
  steps_completed: number;
  steps_total: number;
}

export interface CardDetails extends Card {
  description: string;
  steps: Step[];
  custom_fields: Field[];
  comments: { id: string; author: string; body: string }[];
}
