# Background job to send push notifications when reservations are created or cancelled
#
# Usage:
#   ReservationNotificationJob.perform_later(reservation_id, action: 'created')
#   ReservationNotificationJob.perform_later(reservation_id, action: 'cancelled')
#
class ReservationNotificationJob < ApplicationJob
  queue_as :default

  # @param reservation_id [Integer] ID of the reservation
  # @param action [String] Action performed: 'created' or 'cancelled'
  def perform(reservation_id, action:)
    reservation = Reservation.find_by(id: reservation_id)
    return unless reservation

    tee_time = reservation.tee_time_posting
    return unless tee_time

    # Notify the tee time posting owner
    owner = tee_time.user
    return unless owner

    # Don't notify owner if they made the reservation themselves
    return if reservation.user_id == owner.id

    case action
    when "created"
      send_reservation_created_notification(reservation, tee_time, owner)
    when "cancelled"
      send_reservation_cancelled_notification(reservation, tee_time, owner)
    else
      Rails.logger.warn("Unknown reservation action: #{action}")
    end
  end

  private

  def send_reservation_created_notification(reservation, tee_time, owner)
    reserver = reservation.user
    reserver_name = reserver.name || reserver.email_address.split("@").first

    PushNotificationService.send_to_user(
      owner,
      title: "New Reservation",
      body: "#{reserver_name} reserved a spot for your tee time",
      data: {
        type: "reservation_created",
        tee_time_id: tee_time.id,
        reservation_id: reservation.id
      },
      notification_type: :reservation_created
    )
  end

  def send_reservation_cancelled_notification(reservation, tee_time, owner)
    reserver = reservation.user
    reserver_name = reserver.name || reserver.email_address.split("@").first

    PushNotificationService.send_to_user(
      owner,
      title: "Reservation Cancelled",
      body: "#{reserver_name} cancelled their reservation",
      data: {
        type: "reservation_cancelled",
        tee_time_id: tee_time.id,
        reservation_id: reservation.id
      },
      notification_type: :reservation_cancelled
    )
  end
end
