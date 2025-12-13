FactoryBot.define do
  factory :group_notification_setting do
    association :user
    association :group
    muted { false }

    trait :muted do
      muted { true }
    end
  end
end
