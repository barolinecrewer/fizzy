module Card::Multistep
  extend ActiveSupport::Concern

  included do
    has_many :steps, -> { order(:id) }, dependent: :destroy
  end
end
