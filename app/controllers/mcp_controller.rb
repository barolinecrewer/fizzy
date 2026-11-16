# The account's MCP endpoint: POST /{account}/mcp with a personal access token
# as the bearer. Stateless, so there are no sessions or server-sent streams.
#
# shortcut: every call is a POST, so a read-only token is refused outright
# rather than limited to the read tools; split the tools if that's wanted.
class McpController < ApplicationController
  allow_any_user_agent

  def create
    if response = Mcp::Server.new(Current.user).handle(message)
      render json: response
    else
      head :accepted
    end
  end

  private
    def message
      JSON.parse(request.raw_post)
    rescue JSON::ParserError
      nil
    end
end
