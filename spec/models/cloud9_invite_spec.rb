require 'rails_helper'

RSpec.describe Cloud9Invite, type: :model, vcr: true do
  it { should have_db_column :email }
  it { should validate_presence_of :email }
  it { should validate_uniqueness_of :email }

  it 'ensures that only valid emails are accepted' do
    invite = build(:cloud9_invite)
    invite.email = 'bad_email'

    expect(invite).to be_invalid
    expect(invite.errors[:email]).to include('is not an email')
  end
end
