json.extract! message, :id, :dod, :tod, :dow, :title, :descriptor, :created_at, :updated_at
json.url message_url(message, format: :json)
