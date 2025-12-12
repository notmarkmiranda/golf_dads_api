FactoryBot.define do
  factory :favorite_golf_course do
    association :user
    association :golf_course
  end
end
