require "test_helper"

class Cards::StepsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
  end

  test "create" do
    card = cards(:logo)

    assert_difference -> { card.steps.count }, +1 do
      post card_steps_path(card), params: { step: { content: "Research alternatives" } }, as: :turbo_stream
      assert_turbo_stream action: :before, target: dom_id(card, :new_step)
    end

    assert_equal "Research alternatives", card.steps.last.content
  end

  test "update" do
    card = cards(:logo)
    step = card.steps.create!(content: "Original content")

    assert_changes -> { step.reload.content }, from: "Original content", to: "Updated content" do
      put card_step_path(card, step), params: { step: { content: "Updated content" } }, as: :turbo_stream
      assert_turbo_stream action: :replace, target: dom_id(step)
    end
  end

  test "destroy" do
    card = cards(:logo)
    step = card.steps.create!(content: "Step to delete")

    assert_difference -> { card.steps.count }, -1 do
      delete card_step_path(card, step), as: :turbo_stream
      assert_turbo_stream action: :remove, target: dom_id(step)
    end
  end

  test "toggle completion" do
    card = cards(:logo)
    step = card.steps.create!(content: "Test step", completed: false)

    # Toggle to completed
    assert_changes -> { step.reload.completed? }, from: false, to: true do
      put card_step_path(card, step), params: { step: { completed: "1" } }, as: :turbo_stream
      assert_turbo_stream action: :replace, target: dom_id(step)
    end

    # Toggle back to incomplete
    assert_changes -> { step.reload.completed? }, from: true, to: false do
      put card_step_path(card, step), params: { step: { completed: "0" } }, as: :turbo_stream
      assert_turbo_stream action: :replace, target: dom_id(step)
    end
  end

  test "index as JSON" do
    card = cards(:logo)
    card.steps.create!(content: "Step one")
    card.steps.create!(content: "Step two", completed: true)

    get card_steps_path(card), as: :json
    assert_response :success

    body = @response.parsed_body
    assert_equal 2, body.size
    assert_equal "Step one", body.first["content"]
  end

  test "create as JSON" do
    card = cards(:logo)

    assert_difference -> { card.steps.count }, +1 do
      post card_steps_path(card), params: { step: { content: "New step" } }, as: :json
    end

    assert_response :created
    assert_equal card_step_path(card, Step.last, format: :json), @response.headers["Location"]
    assert_equal "New step", @response.parsed_body["content"]
  end

  test "show as JSON" do
    card = cards(:logo)
    step = card.steps.create!(content: "Test step")

    get card_step_path(card, step), as: :json

    assert_response :success
    assert_equal step.id, @response.parsed_body["id"]
    assert_equal "Test step", @response.parsed_body["content"]
  end

  test "update as JSON" do
    card = cards(:logo)
    step = card.steps.create!(content: "Original")

    put card_step_path(card, step), params: { step: { content: "Updated" } }, as: :json

    assert_response :success
    assert_equal "Updated", step.reload.content
    assert_equal "Updated", @response.parsed_body["content"]
  end

  test "destroy as JSON" do
    card = cards(:logo)
    step = card.steps.create!(content: "To delete")

    delete card_step_path(card, step), as: :json

    assert_response :no_content
    assert_not Step.exists?(step.id)
  end

  test "create nested under a parent with an assignee" do
    card = cards(:logo)
    parent = card.steps.create!(content: "Design:")

    post card_steps_path(card), params: { step: { content: "Sketch", parent_id: parent.id, assignee_id: users(:kevin).id } }, as: :turbo_stream
    assert_turbo_stream action: :before, target: dom_id(parent, :new_step)

    step = card.steps.last
    assert_equal parent, step.parent
    assert_equal users(:kevin), step.assignee
  end

  test "assign on update and show it as JSON" do
    card = cards(:logo)
    step = card.steps.create!(content: "Sketch")

    put card_step_path(card, step), params: { step: { assignee_id: users(:kevin).id } }, as: :json
    assert_response :success
    assert_equal users(:kevin).id, @response.parsed_body["assignee_id"]
    assert_equal false, @response.parsed_body["section"]
  end

  test "edit offers the assignee and a place for sub-steps" do
    card = cards(:logo)
    step = card.steps.create!(content: "Sketch")

    get edit_card_step_path(card, step)
    assert_select "select[name='step[assignee_id]']"
    assert_select "##{dom_id(step, :new_step)}"
  end
end
