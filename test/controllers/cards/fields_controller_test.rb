require "test_helper"

class Cards::FieldsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
    @card = cards(:logo)
    @field = @card.board.custom_fields.create!(name: "Estimate", kind: "number")
  end

  test "update" do
    put card_field_path(@card, @field), params: { value: "3" }, as: :turbo_stream
    assert_response :success
    assert_equal "3", @card.custom_fields[@field]

    get card_path(@card)
    assert_select "input[type=number][value='3']"
  end

  test "update with a value that does not fit" do
    put card_field_path(@card, @field), params: { value: "lots" }, as: :json
    assert_response :unprocessable_entity
  end

  test "values appear in the card JSON" do
    @card.set_custom_field @field, "5"

    get card_path(@card), as: :json
    assert_equal [ { "id" => @field.id, "name" => "Estimate", "kind" => "number", "value" => "5" } ], @response.parsed_body["custom_fields"]
  end
end
