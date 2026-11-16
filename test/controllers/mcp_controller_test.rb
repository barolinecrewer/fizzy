require "test_helper"

class McpControllerTest < ActionDispatch::IntegrationTest
  setup do
    @board = boards(:writebook)
  end

  test "initialize, then list the tools" do
    rpc "initialize", protocolVersion: "2025-06-18"
    assert_equal "fizzy", @response.parsed_body.dig("result", "serverInfo", "name")

    rpc "tools/list"
    tools = @response.parsed_body.dig("result", "tools")
    assert_equal Mcp::Tools::DEFINITIONS.keys.map(&:to_s), tools.pluck("name")
    assert_equal %w[ board_id ], tools.find { it["name"] == "get_board" }.dig("inputSchema", "required")
  end

  test "every described tool is implemented, and nothing else is callable" do
    assert_equal Mcp::Tools::DEFINITIONS.keys.sort, Mcp::Tools.public_instance_methods(false).without(:user).sort
  end

  test "a notification is accepted without a body" do
    post mcp_path, params: { jsonrpc: "2.0", method: "notifications/initialized" }.to_json, headers: headers
    assert_response :accepted
  end

  test "work a card end to end" do
    number = call("create_card", board_id: @board.id, title: "Ship MCP", column_id: columns(:writebook_in_progress).id)["number"]
    assert_equal "In progress", call("get_card", number: number)["column"]

    section = call("add_step", number: number, content: "Build:")
    step = call("add_step", number: number, content: "Write tools", parent_id: section["id"], assignee_id: users(:david).id)
    call("update_step", number: number, step_id: step["id"], completed: true)

    template = call("create_step_template", name: "QA", outline: "Test:\n  Click around")
    call("apply_step_template", number: number, template_id: template["id"])

    field = call("create_custom_field", board_id: @board.id, name: "Priority", kind: "select", options: "Low, High")
    call("set_custom_field", number: number, field_id: field["id"], value: "High")
    call("comment_on_card", number: number, body: "Done from MCP")

    card = call("get_card", number: number)
    assert_equal [ "Build:", "Test:" ], card["steps"].pluck("content")
    assert_equal({ "content" => "Write tools", "completed" => true, "assignee" => "David" }, card["steps"].first["steps"].first.slice("content", "completed", "assignee"))
    assert_equal [ 1, 2 ], card.values_at("steps_completed", "steps_total")
    assert_equal "High", card["custom_fields"].first["value"]
    assert_equal "Done from MCP", card["comments"].last["body"]

    assert call("move_card", number: number, destination: "closed")["closed"]
    assert_includes call("list_cards", board_id: @board.id, status: "closed").pluck("number"), number
    assert_not_includes call("list_cards", board_id: @board.id).pluck("number"), number
  end

  test "tool failures come back as tool errors" do
    assert_match(/Couldn't find/, call("get_card", expect_error: true, number: 999_999))
    assert_match(/unknown keyword/, call("get_card", expect_error: true, number: 1, nonsense: true))
    assert_match(/Unknown tool/, call("card", expect_error: true, number: 1))
    assert_match(/must be one of|Validation failed/, call("add_step", expect_error: true, number: 1, content: ""))
  end

  test "boards the user cannot access are out of reach" do
    assert_match(/Couldn't find/, call("get_board", expect_error: true, board_id: boards(:miltons_wish_list).id))
  end

  test "unknown methods and bad tokens are refused" do
    rpc "resources/list"
    assert_equal(-32601, @response.parsed_body.dig("error", "code"))

    post mcp_path, params: { jsonrpc: "2.0", id: 1, method: "ping" }.to_json, headers: headers.merge("Authorization" => "Bearer nope")
    assert_response :unauthorized

    post mcp_path, params: { jsonrpc: "2.0", id: 1, method: "ping" }.to_json,
      headers: headers.merge("Authorization" => "Bearer #{identity_access_tokens(:jasons_api_token).token}")
    assert_response :unauthorized
  end

  private
    # What an MCP client sends: a two-type Accept header and a bearer token.
    def headers
      { "Content-Type" => "application/json", "Accept" => "application/json, text/event-stream",
        "Authorization" => "Bearer #{identity_access_tokens(:davids_api_token).token}" }
    end

    def rpc(method, **params)
      post mcp_path, params: { jsonrpc: "2.0", id: 1, method: method, params: params }.to_json, headers: headers
      assert_response :success
    end

    def call(name, expect_error: false, **arguments)
      rpc "tools/call", name: name, arguments: arguments
      result = @response.parsed_body["result"]
      text = result.dig("content", 0, "text")

      assert_equal expect_error, result["isError"], text
      expect_error ? text : JSON.parse(text)
    end
end
