class Step < ApplicationRecord
  belongs_to :account, default: -> { card.account }
  belongs_to :card, touch: true
  belongs_to :parent, class_name: "Step", optional: true
  belongs_to :assignee, class_name: "User", optional: true

  has_many :children, -> { order(:id) }, class_name: "Step", foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy

  scope :completed, -> { where(completed: true) }
  scope :roots, -> { where(parent_id: nil).order(:id) }
  scope :tasks, -> { where.not("content LIKE ?", "%:") }

  validates :content, presence: true
  validate :parent_on_same_card
  # Only when assigning: someone who later loses access must not make the step unsaveable.
  validate :assignee_can_access_board, if: :assignee_id_changed?

  def completed?
    completed
  end

  # As in Asana, a step whose name ends with a colon is a section heading.
  def section?
    content.to_s.end_with?(":")
  end

  private
    def parent_on_same_card
      errors.add(:parent, "must be a step on the same card") if parent && (parent.card_id != card_id || parent == self)
    end

    def assignee_can_access_board
      errors.add(:assignee, "must have access to the board") if assignee && !card.board.accessible_to?(assignee)
    end
end
