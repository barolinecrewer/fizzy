require "test_helper"

class StepTest < ActiveSupport::TestCase
  setup do
    @card = cards(:logo)
  end

  test "a step ending with a colon is a section and not counted as a task" do
    @card.steps.create!(content: "Design:")
    @card.steps.create!(content: "Sketch")

    assert @card.steps.first.section?
    assert_equal %w[ Sketch ], @card.steps.tasks.map(&:content)
  end

  test "steps nest, and deleting a parent deletes what is under it" do
    parent = @card.steps.create!(content: "Parent")
    child = @card.steps.create!(content: "Child", parent: parent)
    @card.steps.create!(content: "Grandchild", parent: child)

    assert_equal [ parent ], @card.steps.roots.to_a
    assert_difference -> { Step.count }, -3 do
      parent.destroy!
    end
  end

  test "a parent must be on the same card" do
    other = cards(:text).steps.create!(content: "Elsewhere")

    assert_not @card.steps.build(content: "Child", parent: other).valid?
  end

  test "an assignee must have access to the board" do
    assert @card.steps.build(content: "Mine", assignee: users(:kevin)).valid?
    assert_not @card.steps.build(content: "Theirs", assignee: users(:mike)).valid?
  end

  test "a step stays editable after its assignee loses access" do
    step = @card.steps.create!(content: "Mine", assignee: users(:kevin))
    @card.board.accesses.where(user: users(:kevin)).delete_all

    assert step.reload.update(completed: true)
  end
end
