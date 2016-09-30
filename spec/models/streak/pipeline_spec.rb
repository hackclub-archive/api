require 'rails_helper'

RSpec.describe Streak::Pipeline, type: :model do
  subject { create(:streak_pipeline) }

  it { should have_many :fields }

  it { should have_db_column :streak_key }
  it { should have_db_column :name }

  it { should validate_presence_of :streak_key }
  it { should validate_presence_of :name }

  it { should validate_uniqueness_of :streak_key }
end
