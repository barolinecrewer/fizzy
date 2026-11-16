# A reusable list of steps, kept as an indented outline: one step per line,
# two spaces of indent per level, and a trailing colon for a section.
class StepTemplate < ApplicationRecord
  belongs_to :account, default: -> { Current.account }

  validates :name, :outline, presence: true

  scope :alphabetically, -> { order("lower(name)") }

  def self.outline_of(card)
    outline_lines(card.steps.roots).join("\n")
  end

  def self.outline_lines(steps, depth = 0)
    steps.flat_map { |step| [ "#{"  " * depth}#{step.content}", *outline_lines(step.children, depth + 1) ] }
  end

  def apply_to(card)
    transaction do
      parents = []

      outline.each_line do |line|
        if content = line.strip.sub(/\A[-*]\s+/, "").presence
          depth = [ line[/\A\s*/].size / 2, parents.size ].min
          step = card.steps.create!(content: content, parent: (parents[depth - 1] if depth.positive?))
          parents = parents.first(depth) << step
        end
      end
    end
  end
end
