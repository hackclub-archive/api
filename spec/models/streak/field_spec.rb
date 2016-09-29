require 'rails_helper'

RSpec.describe Streak::Field, type: :model do
  subject { create(:streak_field) }

  it { should have_db_column :streak_key }
  it { should have_db_column :streak_pipeline_id }
  it { should have_db_column :name }
  it { should have_db_column :field_type }

  it { should validate_presence_of :streak_key }
  it { should validate_presence_of :pipeline }
  it { should validate_presence_of :name }
  it { should validate_presence_of :field_type }

  it { should validate_uniqueness_of(:streak_key)
               .scoped_to(:streak_pipeline_id) }
end
