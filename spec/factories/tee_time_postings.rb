FactoryBot.define do
  factory :tee_time_posting do
    association :user
    tee_time { 2.days.from_now }
    course_name { Faker::Company.name + " Golf Club" }
    total_spots { 4 }
    notes { Faker::Lorem.sentence }

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
