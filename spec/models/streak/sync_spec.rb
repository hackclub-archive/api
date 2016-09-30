require 'rails_helper'

RSpec.describe Streak::Sync, type: :model do
  subject { create(:streak_sync) }

  it { should have_db_column :streak_pipeline_id }
  it { should have_db_column :dest_table }

  it { should validate_presence_of :pipeline }
  it { should validate_presence_of :dest_table }

  it { should validate_uniqueness_of(:dest_table)
               .scoped_to(:streak_pipeline_id) }
end
