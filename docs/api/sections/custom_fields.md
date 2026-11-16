# Custom fields

Custom fields belong to a board and appear on every card in it. A field's `kind` is `text`, `number`, `date` or `select`; a select field lists its choices in `options`.

## `GET /:account_slug/boards/:board_id/custom_fields`

Lists a board's fields.

```json
[ { "id": "03f5v9zo9qlcwwpyc0ascnikz", "name": "Priority", "kind": "select", "options": [ "Low", "High" ] } ]
```

## `POST /:account_slug/boards/:board_id/custom_fields`

Adds a field. Board admins only.

```json
{ "custom_field": { "name": "Priority", "kind": "select", "options": "Low, High" } }
```

## `DELETE /:account_slug/boards/:board_id/custom_fields/:id`

Removes a field and its values from every card. Board admins only.

## `PUT /:account_slug/cards/:card_number/fields/:custom_field_id`

Sets the card's value for a field from `{ "value": "High" }`. An empty value clears it. Dates are `YYYY-MM-DD`. A value that doesn't fit the field's kind returns `422`.

A card's values are included as `custom_fields` in `GET /:account_slug/cards/:card_number`.
