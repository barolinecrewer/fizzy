# Steps

Steps are to-do items on a card. A step can nest under another step (`parent_id`), be assigned to one person with access to the board (`assignee_id`), and becomes a section heading when its content ends with a colon (`section`).

## `GET /:account_slug/cards/:card_number/steps/:step_id`

Returns a specific step.

__Response:__

```json
{
  "id": "03f5v9zo9qlcwwpyc0ascnikz",
  "content": "Write tests",
  "completed": false,
  "parent_id": null,
  "assignee_id": null,
  "section": false
}
```

## `POST /:account_slug/cards/:card_number/steps`

Creates a new step on a card.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `content` | string | Yes | The step text |
| `completed` | boolean | No | Whether the step is completed (default: `false`) |
| `parent_id` | string | No | The step or section to nest this one under. Set on creation only |
| `assignee_id` | string | No | The user the step is assigned to |

__Request:__

```json
{
  "step": {
    "content": "Write tests"
  }
}
```

__Response:__

Returns `201 Created` with a `Location` header pointing to the new step.

## `PUT /:account_slug/cards/:card_number/steps/:step_id`

Updates a step.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `content` | string | No | The step text |
| `completed` | boolean | No | Whether the step is completed |
| `assignee_id` | string | No | The user the step is assigned to; empty to unassign |

__Request:__

```json
{
  "step": {
    "completed": true
  }
}
```

__Response:__

Returns the updated step.

## `DELETE /:account_slug/cards/:card_number/steps/:step_id`

Deletes a step.

__Response:__

Returns `204 No Content` on success.

## Step templates

A template is a reusable outline of steps: one per line, two spaces of indent per nesting level, and a trailing colon for a section.

- `GET /:account_slug/step_templates` lists them.
- `POST /:account_slug/step_templates` creates one from `{ "step_template": { "name": "…", "outline": "…" } }`, or from a card's current steps with `{ "card_id": 42 }`.
- `PUT` and `DELETE /:account_slug/step_templates/:id` change and remove one.
- `POST /:account_slug/cards/:card_number/templatings` with `{ "step_template_id": "…" }` adds a template's steps to a card.
