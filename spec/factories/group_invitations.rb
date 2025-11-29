FactoryBot.define do
  factory :group_invitation do
    association :group
    association :inviter, factory: :user
    invitee_email { Faker::Internet.email }
    status { "pending" }
    token { SecureRandom.urlsafe_base64(32) }

    trait :pending do
      status { "pending" }
    end

    trait :accepted do
      status { "accepted" }
    end

    trait :rejected do
      status { "rejected" }
    end
  end
end
