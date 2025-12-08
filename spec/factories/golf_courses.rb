FactoryBot.define do
  factory :golf_course do
    sequence(:name) { |n| "Golf Course #{n}" }
    address { "123 Golf Lane" }
    city { "Golf City" }
    state { "CA" }
    zip_code { "12345" }
    country { "USA" }
    latitude { 36.5674 }
    longitude { -121.9500 }
    phone { "(555) 123-4567" }
    website { "https://example.com" }

    trait :without_coordinates do
      latitude { nil }
      longitude { nil }
    end

    trait :pebble_beach do
      name { "Pebble Beach Golf Links" }
      address { "1700 17 Mile Dr" }
      city { "Pebble Beach" }
      state { "CA" }
      zip_code { "93953" }
      latitude { 36.5674 }
      longitude { -121.9500 }
    end

    trait :augusta do
      name { "Augusta National Golf Club" }
      address { "2604 Washington Rd" }
      city { "Augusta" }
      state { "GA" }
      zip_code { "30904" }
      latitude { 33.5027 }
      longitude { -82.0201 }
    end
  end
end
