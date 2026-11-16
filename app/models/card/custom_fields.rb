module Card::CustomFields
  extend ActiveSupport::Concern

  included do
    has_many :custom_field_values, dependent: :delete_all
  end

  # The board's fields with this card's value for each, nil where unset.
  def custom_fields
    values = custom_field_values.index_by(&:custom_field_id)
    board.custom_fields.alphabetically.index_with { |field| values[field.id]&.value }
  end

  def set_custom_field(field, value)
    record = custom_field_values.find_or_initialize_by(custom_field: board.custom_fields.find(field.id))

    if value.present?
      record.update!(value: value.to_s.strip)
    else
      record.destroy!
    end

    custom_field_values.reset
  end
end
