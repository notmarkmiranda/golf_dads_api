FactoryBot.define do
  factory :tee_time_posting do
    association :user
    tee_time { 2.days.from_now }
    course_name { Faker::Company.name + " Golf Club" }
    available_spots { 2 }
    total_spots { 4 }
    notes { Faker::Lorem.sentence }

    trait :public do
      group { nil }
    end

    trait :group_posting do
      association :group
    end

    trait :past do
      # Create with future time, then update to past to bypass validation
      after(:create) do |posting|
        posting.update_column(:tee_time, 2.days.ago)
      end
    end

    trait :upcoming do
      tee_time { 3.days.from_now }
    end
  end
end
