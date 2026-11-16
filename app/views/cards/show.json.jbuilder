json.partial! "cards/card", card: @card
json.steps @card.steps, partial: "cards/steps/step", as: :step
json.custom_fields @card.custom_fields do |field, value|
  json.(field, :id, :name, :kind)
  json.value value
end
