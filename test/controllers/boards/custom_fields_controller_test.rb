require "test_helper"

class Boards::CustomFieldsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
    @board = boards(:writebook)
  end

  test "create and destroy" do
    assert_difference -> { @board.custom_fields.count }, +1 do
      post board_custom_fields_path(@board), params: { custom_field: { name: "Priority", kind: "select", options: "Low, High" } }
      assert_redirected_to edit_board_path(@board)
    end

    get edit_board_path(@board)
    assert_select "strong", text: "Priority"

    assert_difference -> { @board.custom_fields.count }, -1 do
      delete board_custom_field_path(@board, @board.custom_fields.last)
    end
  end

  test "index as JSON" do
    @board.custom_fields.create!(name: "Priority", kind: "select", options: "Low, High")

    get board_custom_fields_path(@board), as: :json
    assert_equal [ %w[ Low High ] ], @response.parsed_body.pluck("options")
  end

  test "only board admins can add fields" do
    logout_and_sign_in_as :jz

    post board_custom_fields_path(@board), params: { custom_field: { name: "Priority" } }
    assert_response :forbidden
  end
end
