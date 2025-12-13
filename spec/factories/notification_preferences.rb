FactoryBot.define do
  factory :notification_preference do
    association :user
    reservations_enabled { true }
    group_activity_enabled { true }
    reminders_enabled { true }
    reminder_24h_enabled { true }
    reminder_2h_enabled { true }

    trait :all_disabled do
      reservations_enabled { false }
      group_activity_enabled { false }
      reminders_enabled { false }
      reminder_24h_enabled { false }
      reminder_2h_enabled { false }
    end

    trait :reminders_disabled do
      reminders_enabled { false }
    end
  end
end
