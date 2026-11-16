require "test_helper"

class StepTemplateTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
    @card = cards(:logo)
  end

  test "apply an outline as nested steps and sections" do
    template = StepTemplate.create!(name: "Launch", outline: "Design:\n  Sketch\n    - Thumbnails\n  Review\n\nShip it\n")

    assert_difference -> { @card.steps.count }, +5 do
      template.apply_to(@card)
    end

    design, ship = @card.steps.roots.last(2)
    assert design.section?
    assert_not ship.section?
    assert_equal %w[ Sketch Review ], design.children.map(&:content)
    assert_equal %w[ Thumbnails ], design.children.first.children.map(&:content)
  end

  test "an outline round-trips through a card" do
    outline = "Design:\n  Sketch\n    Thumbnails\n  Review\nShip it"
    StepTemplate.create!(name: "Launch", outline: outline).apply_to(@card)

    assert_equal outline, StepTemplate.outline_of(@card)
  end
end
