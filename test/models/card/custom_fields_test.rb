require "test_helper"

class Card::CustomFieldsTest < ActiveSupport::TestCase
  setup do
    @card = cards(:logo)
    @priority = @card.board.custom_fields.create!(name: "Priority", kind: "select", options: "Low, High")
    @estimate = @card.board.custom_fields.create!(name: "Estimate", kind: "number")
  end

  test "set, replace and clear a value" do
    @card.set_custom_field @priority, "High"
    assert_equal({ @estimate => nil, @priority => "High" }, @card.custom_fields)

    @card.set_custom_field @priority, "Low"
    assert_equal "Low", @card.custom_fields[@priority]

    @card.set_custom_field @priority, ""
    assert_nil @card.custom_fields[@priority]
  end

  test "values must fit the kind of field" do
    assert_raises(ActiveRecord::RecordInvalid) { @card.set_custom_field @priority, "Urgent" }
    assert_raises(ActiveRecord::RecordInvalid) { @card.set_custom_field @estimate, "lots" }

    date = @card.board.custom_fields.create!(name: "Due", kind: "date")
    assert_raises(ActiveRecord::RecordInvalid) { @card.set_custom_field date, "tomorrow" }
    @card.set_custom_field date, "2026-12-01"
  end

  test "a field from another board is refused" do
    field = boards(:private).custom_fields.create!(name: "Secret")

    assert_raises(ActiveRecord::RecordNotFound) { @card.set_custom_field field, "x" }
  end

  test "a select field needs options" do
    assert_not @card.board.custom_fields.build(name: "Size", kind: "select").valid?
  end
end
