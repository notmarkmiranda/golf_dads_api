FactoryBot.define do
  factory :notification_log do
    association :user
    notification_type { 'reservation_created' }
    title { 'New Reservation' }
    body { 'Someone reserved a spot for your tee time' }
    data { { tee_time_id: 1, reservation_id: 1 } }
    status { 'pending' }
    error_message { nil }
    sent_at { nil }

    trait :sent do
      status { 'sent' }
      sent_at { Time.current }
    end

    trait :failed do
      status { 'failed' }
      error_message { 'FCM token invalid' }
    end

    trait :reservation_cancelled do
      notification_type { 'reservation_cancelled' }
      title { 'Reservation Cancelled' }
      body { 'Someone cancelled their reservation' }
    end

    trait :group_tee_time do
      notification_type { 'group_tee_time' }
      title { 'New Tee Time Posted' }
      body { 'A new tee time was posted in your group' }
      data { { tee_time_id: 1, group_id: 1 } }
    end

    trait :reminder_24h do
      notification_type { 'reminder_24h' }
      title { 'Tee Time Tomorrow' }
      body { 'Your tee time is tomorrow at 2:00 PM' }
      data { { tee_time_id: 1, timeframe: '24 hours' } }
    end

    trait :reminder_2h do
      notification_type { 'reminder_2h' }
      title { 'Tee Time Soon' }
      body { 'Your tee time is in 2 hours' }
      data { { tee_time_id: 1, timeframe: '2 hours' } }
    end
  end
end
