# A stateless Model Context Protocol server speaking JSON-RPC over HTTP.
# McpController hands it each decoded message; Mcp::Tools does the work.
class Mcp::Server
  PROTOCOL_VERSION = "2025-06-18"

  TOOL_ERRORS = [ ActiveRecord::RecordInvalid, ArgumentError, TypeError ]

  attr_reader :user

  def initialize(user)
    @user = user
  end

  # Returns the response to send, or nil when the message was a notification.
  def handle(message)
    if message.is_a?(Array)
      message.filter_map { handle(it) }.presence
    elsif !message.is_a?(Hash)
      error nil, -32600, "Invalid request"
    elsif message.key?("id")
      respond_to message
    end
  end

  private
    def respond_to(message)
      case message["method"]
      when "initialize" then result message, initialization(message.dig("params", "protocolVersion"))
      when "ping"       then result message, {}
      when "tools/list" then result message, tools: Mcp::Tools.definitions
      when "tools/call" then result message, call_tool(message.dig("params", "name"), message.dig("params", "arguments"))
      else error message["id"], -32601, "Method not found"
      end
    end

    def initialization(requested_version)
      { protocolVersion: requested_version || PROTOCOL_VERSION, capabilities: { tools: {} }, serverInfo: { name: "fizzy", version: "1.0" } }
    end

    def call_tool(name, arguments)
      if Mcp::Tools::DEFINITIONS.key?(name.to_s.to_sym)
        tool_result Mcp::Tools.new(user).public_send(name, **arguments.to_h.symbolize_keys).to_json
      else
        tool_result "Unknown tool: #{name}", error: true
      end
    rescue ActiveRecord::RecordNotFound => e
      tool_result "Couldn't find that #{e.model.to_s.underscore.humanize(capitalize: false)}", error: true
    rescue *TOOL_ERRORS => e
      tool_result e.message, error: true
    end

    def tool_result(text, error: false)
      { content: [ { type: "text", text: text } ], isError: error }
    end

    def result(message, result)
      { jsonrpc: "2.0", id: message["id"], result: result }
    end

    def error(id, code, message)
      { jsonrpc: "2.0", id: id, error: { code: code, message: message } }
    end
end
