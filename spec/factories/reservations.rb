FactoryBot.define do
  factory :reservation do
    association :user
    association :tee_time_posting
    spots_reserved { 1 }
  end
end
