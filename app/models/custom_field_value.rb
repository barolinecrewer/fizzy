class CustomFieldValue < ApplicationRecord
  belongs_to :account, default: -> { card.account }
  belongs_to :card, touch: true
  belongs_to :custom_field

  validates :value, presence: true
  validate :value_fits_field_kind

  private
    def value_fits_field_kind
      case custom_field&.kind
      when "number" then errors.add(:value, "must be a number") unless Float(value, exception: false)
      when "date"   then errors.add(:value, "must be a date") unless (Date.iso8601(value) rescue nil)
      when "select" then errors.add(:value, "must be one of #{custom_field.choices.to_sentence}") unless custom_field.choices.include?(value)
      end
    end
end
