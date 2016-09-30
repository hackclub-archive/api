class Streak::FieldSerializer < ActiveModel::Serializer
  attributes :id, :created_at, :updated_at, :streak_key, :name
  attribute :field_type, key: :type
end
