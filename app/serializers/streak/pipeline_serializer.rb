class Streak::PipelineSerializer < ActiveModel::Serializer
  attributes :id, :created_at, :updated_at, :streak_key, :name

  has_many :fields
end
