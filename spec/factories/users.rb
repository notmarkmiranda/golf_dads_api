FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    name { Faker::Name.name }
    password { "password123" }
    password_confirmation { "password123" }
    provider { nil }
    uid { nil }

    trait :oauth_user do
      provider { "google" }
      sequence(:uid) { |n| "google_uid_#{n}" }
      password { nil }
      password_confirmation { nil }
      avatar_url { Faker::Avatar.image }
    end
  end
end
