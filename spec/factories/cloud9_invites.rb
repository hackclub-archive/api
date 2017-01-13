FactoryGirl.define do
  factory :cloud9_invite do
    email { Faker::Internet.email }
  end
end
