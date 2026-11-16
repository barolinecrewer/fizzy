require "test_helper"

class StepTemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
  end

  test "create, update and destroy" do
    post step_templates_path, params: { step_template: { name: "Launch", outline: "Ship it" } }
    assert_redirected_to step_templates_path
    template = StepTemplate.last

    patch step_template_path(template), params: { step_template: { name: "Launch", outline: "Ship it\nCelebrate" } }
    assert_equal "Ship it\nCelebrate", template.reload.outline

    get step_templates_path
    assert_select "textarea", text: /Celebrate/

    assert_difference -> { StepTemplate.count }, -1 do
      delete step_template_path(template)
    end
  end

  test "create from a card's steps" do
    card = cards(:logo)
    parent = card.steps.create!(content: "Design:")
    card.steps.create!(content: "Sketch", parent: parent)

    post step_templates_path, params: { card_id: card.number }
    assert_equal "Design:\n  Sketch", StepTemplate.last.outline
  end

  test "index as JSON" do
    StepTemplate.create!(account: accounts("37s"), name: "Launch", outline: "Ship it")

    get step_templates_path, as: :json
    assert_equal [ "Launch" ], @response.parsed_body.pluck("name")
  end
end
