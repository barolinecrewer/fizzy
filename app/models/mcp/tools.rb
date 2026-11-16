# The tools the MCP server offers. Each public method is a tool, called with
# the client's arguments as keywords, acting as the user and returning data
# to serialize. A tool is only callable once it is described in DEFINITIONS.
class Mcp::Tools
  CARD_LIMIT = 200
  COMMENT_LIMIT = 20

  # name => [ description, { argument => type } ], where a trailing ! marks the argument required.
  DEFINITIONS = {
    list_boards: [ "List the boards you can access.", {} ],
    get_board: [ "A board's columns, custom fields and people. Use the ids it returns with the other tools.", { board_id: "string!" } ],
    list_cards: [ "Cards on a board, most recently active first. status is open (default), closed, not_now or all. A card with no column is awaiting triage.",
      { board_id: "string!", column_id: "string", status: "string" } ],
    get_card: [ "A card in full: description, nested steps, custom fields and recent comments.", { number: "integer!" } ],
    create_card: [ "Create a card on a board, optionally straight into a column.",
      { board_id: "string!", title: "string!", description: "string", column_id: "string" } ],
    update_card: [ "Change a card's title or description.", { number: "integer!", title: "string", description: "string" } ],
    move_card: [ "Move a card. destination is a column id, or one of: triage, not_now, closed.", { number: "integer!", destination: "string!" } ],
    assign_card: [ "Toggle a person's assignment to a card.", { number: "integer!", user_id: "string!" } ],
    comment_on_card: [ "Add a comment to a card.", { number: "integer!", body: "string!" } ],
    add_step: [ "Add a step (subtask) to a card. Give parent_id to nest it under another step or section. Content ending with a colon makes a section heading.",
      { number: "integer!", content: "string!", parent_id: "string", assignee_id: "string" } ],
    update_step: [ "Rename, complete, or assign a step. An empty assignee_id unassigns it.",
      { number: "integer!", step_id: "string!", content: "string", completed: "boolean", assignee_id: "string" } ],
    delete_step: [ "Delete a step and everything nested under it.", { number: "integer!", step_id: "string!" } ],
    list_step_templates: [ "List the reusable step templates.", {} ],
    create_step_template: [ "Save a step template. outline has one step per line, two spaces of indent per nesting level, and a trailing colon for a section.",
      { name: "string!", outline: "string!" } ],
    apply_step_template: [ "Add a template's steps to a card.", { number: "integer!", template_id: "string!" } ],
    create_custom_field: [ "Add a custom field to a board. kind is text (default), number, date or select; select needs comma-separated options.",
      { board_id: "string!", name: "string!", kind: "string", options: "string" } ],
    set_custom_field: [ "Set a card's value for one of its board's custom fields. Omit value to clear it. Dates are YYYY-MM-DD.",
      { number: "integer!", field_id: "string!", value: "string" } ]
  }

  def self.definitions
    DEFINITIONS.map do |name, (description, arguments)|
      { name: name, description: description, inputSchema: {
        type: "object",
        properties: arguments.transform_values { { type: it.delete_suffix("!") } },
        required: arguments.select { |_, type| type.end_with?("!") }.keys
      } }
    end
  end

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def list_boards
    user.boards.alphabetically.map { { id: it.id, name: it.name } }
  end

  def get_board(board_id:)
    board = board(board_id)

    { id: board.id, name: board.name,
      columns: board.columns.sorted.map { { id: it.id, name: it.name, color: it.color.to_s } },
      custom_fields: board.custom_fields.alphabetically.map { custom_field_summary(it) },
      users: board.users.active.alphabetically.map { { id: it.id, name: it.name } } }
  end

  def list_cards(board_id:, column_id: nil, status: "open")
    cards = board(board_id).cards.published.preloaded.latest
    cards = cards.where(column_id: column_id) if column_id

    case status
    when "open"    then cards.active
    when "closed"  then cards.closed
    when "not_now" then cards.postponed
    when "all"     then cards
    else raise ArgumentError, "status must be open, closed, not_now or all"
    end.limit(CARD_LIMIT).map { card_summary(it) }
  end

  def get_card(number:)
    card_details card(number)
  end

  def create_card(board_id:, title:, description: nil, column_id: nil)
    board = board(board_id)
    column = board.columns.find(column_id) if column_id

    board.cards.create!(title: title, description: description, creator: user, status: "published").then do |card|
      card.triage_into(column) if column
      card_details card
    end
  end

  def update_card(number:, title: nil, description: nil)
    card(number).then do |card|
      card.update!({ title: title, description: description }.compact)
      card_details card
    end
  end

  def move_card(number:, destination:)
    card(number).then do |card|
      case destination
      when "triage"  then card.send_back_to_triage
      when "not_now" then card.postpone
      when "closed"  then card.close
      else card.triage_into card.board.columns.find(destination)
      end

      card_summary card.reload
    end
  end

  def assign_card(number:, user_id:)
    card(number).then do |card|
      card.toggle_assignment card.board.users.active.find(user_id)
      card_summary card.reload
    end
  end

  def comment_on_card(number:, body:)
    card(number).comments.create!(body: body, creator: user).then { { id: it.id } }
  end

  def add_step(number:, content:, parent_id: nil, assignee_id: nil)
    card(number).then do |card|
      parent = card.steps.find(parent_id) if parent_id
      step_summary card.steps.create!(content: content, parent: parent, assignee_id: assignee_id.presence)
    end
  end

  def update_step(number:, step_id:, content: nil, completed: nil, assignee_id: nil)
    card(number).steps.find(step_id).then do |step|
      step.update!({ content: content, completed: completed }.compact)
      step.update!(assignee_id: assignee_id.presence) unless assignee_id.nil?
      step_summary step
    end
  end

  def delete_step(number:, step_id:)
    card(number).steps.find(step_id).destroy!
    { deleted: step_id }
  end

  def list_step_templates
    user.account.step_templates.alphabetically.map { step_template_summary(it) }
  end

  def create_step_template(name:, outline:)
    step_template_summary user.account.step_templates.create!(name: name, outline: outline)
  end

  def apply_step_template(number:, template_id:)
    card(number).then do |card|
      user.account.step_templates.find(template_id).apply_to(card)
      card_details card.reload
    end
  end

  def create_custom_field(board_id:, name:, kind: "text", options: nil)
    board = board(board_id)
    raise ArgumentError, "Only a board's admins can add custom fields" unless user.can_administer_board?(board)

    custom_field_summary board.custom_fields.create!(name: name, kind: kind, options: options)
  end

  def set_custom_field(number:, field_id:, value: nil)
    card(number).then do |card|
      card.set_custom_field card.board.custom_fields.find(field_id), value
      { custom_fields: custom_field_values(card.reload) }
    end
  end

  private
    def board(id)
      user.boards.find(id)
    end

    def card(number)
      user.accessible_cards.find_by!(number: number)
    end

    def card_summary(card)
      { number: card.number, title: card.title, board_id: card.board_id,
        column_id: card.column_id, column: card.column&.name,
        closed: card.closed?, not_now: card.postponed?, golden: card.golden?,
        assignees: card.assignees.map(&:name), tags: card.tags.map(&:title),
        steps_completed: card.steps.count { it.completed? && !it.section? }, steps_total: card.steps.count { !it.section? },
        last_active_at: card.last_active_at }
    end

    def card_details(card)
      card_summary(card).merge \
        description: card.description.to_plain_text,
        steps: step_tree(card.steps.includes(:assignee).to_a),
        custom_fields: custom_field_values(card),
        comments: card.comments.chronologically.last(COMMENT_LIMIT).map { comment_summary(it) }
    end

    def step_tree(steps, parent_id = nil)
      steps.select { it.parent_id == parent_id }.map { step_summary(it).merge(steps: step_tree(steps, it.id)) }
    end

    def step_summary(step)
      { id: step.id, content: step.content, section: step.section?, completed: step.completed?,
        parent_id: step.parent_id, assignee_id: step.assignee_id, assignee: step.assignee&.name }
    end

    def step_template_summary(step_template)
      { id: step_template.id, name: step_template.name, outline: step_template.outline }
    end

    def custom_field_summary(field)
      { id: field.id, name: field.name, kind: field.kind, options: field.choices }
    end

    def custom_field_values(card)
      card.custom_fields.map { |field, value| custom_field_summary(field).merge(value: value) }
    end

    def comment_summary(comment)
      { id: comment.id, author: comment.creator.name, body: comment.body.to_plain_text, created_at: comment.created_at }
    end
end
