FactoryBot.define do
  factory :device_token do
    association :user
    sequence(:token) { |n| "fcm_token_#{n}_#{SecureRandom.hex(32)}" }
    platform { 'ios' }
    last_used_at { Time.current }

    trait :android do
      platform { 'android' }
    end

    trait :stale do
      last_used_at { 31.days.ago }
    end
  end
end
