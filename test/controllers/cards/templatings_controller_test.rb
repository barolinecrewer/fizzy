require "test_helper"

class Cards::TemplatingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
    @card = cards(:logo)
    @template = StepTemplate.create!(account: @card.account, name: "Launch", outline: "Design:\n  Sketch")
  end

  test "new lists the templates" do
    get new_card_templating_path(@card)
    assert_select "button", text: "Launch"
  end

  test "create adds the template's steps" do
    assert_difference -> { @card.steps.count }, +2 do
      post card_templatings_path(@card), params: { step_template_id: @template.id }, as: :turbo_stream
      assert_response :success
    end
  end
end
