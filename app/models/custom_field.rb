class CustomField < ApplicationRecord
  KINDS = %w[ text number date select ]

  belongs_to :account, default: -> { board.account }
  belongs_to :board, touch: true

  has_many :values, class_name: "CustomFieldValue", dependent: :delete_all

  validates :name, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :options, presence: true, if: :select?

  # Cards cache their rendered fields, so adding or removing one must expire them.
  after_commit -> { board.cards.touch_all }, on: %i[ create update destroy ]

  scope :alphabetically, -> { order("lower(name)") }

  def select?
    kind == "select"
  end

  def choices
    options.to_s.split(",").map(&:strip).compact_blank
  end
end
