json.cache! step do
  json.(step, :id, :content, :completed, :parent_id, :assignee_id)
  json.section step.section?
end
