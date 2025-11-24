FactoryBot.define do
  factory :group do
    sequence(:name) { |n| "Golf Group #{n}" }
    description { Faker::Lorem.sentence }
    association :owner, factory: :user
  end
end
