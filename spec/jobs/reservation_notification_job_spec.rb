require 'rails_helper'

RSpec.describe ReservationNotificationJob, type: :job do
  let(:owner) { create(:user, name: 'Owner') }
  let(:reserver) { create(:user, name: 'Reserver') }
  let(:golf_course) { create(:golf_course, name: 'Test Course') }
  let(:tee_time) { create(:tee_time_posting, user: owner, golf_course: golf_course) }
  let(:reservation) { create(:reservation, user: reserver, tee_time_posting: tee_time) }

  before do
    # Stub PushNotificationService to avoid actual API calls
    allow(PushNotificationService).to receive(:send_to_user).and_return(true)
  end

  describe '#perform' do
    context 'with action: created' do
      it 'sends notification to tee time owner' do
        expect(PushNotificationService).to receive(:send_to_user).with(
          owner,
          title: 'New Reservation',
          body: /Reserver reserved a spot/,
          data: {
            type: 'reservation_created',
            tee_time_id: tee_time.id,
            reservation_id: reservation.id
          },
          notification_type: :reservation_created
        )

        ReservationNotificationJob.perform_now(reservation.id, action: 'created')
      end

      it 'does not send notification if owner is the reserver' do
        self_reservation = create(:reservation, user: owner, tee_time_posting: tee_time)

        expect(PushNotificationService).not_to receive(:send_to_user)

        ReservationNotificationJob.perform_now(self_reservation.id, action: 'created')
      end

      it 'uses email prefix if user has no name' do
        reserver.update_columns(name: nil, email_address: 'test@example.com')

        expect(PushNotificationService).to receive(:send_to_user).with(
          owner,
          title: 'New Reservation',
          body: /test reserved a spot/,
          data: anything,
          notification_type: :reservation_created
        )

        ReservationNotificationJob.perform_now(reservation.id, action: 'created')
      end
    end

    context 'with action: cancelled' do
      it 'sends notification to tee time owner' do
        expect(PushNotificationService).to receive(:send_to_user).with(
          owner,
          title: 'Reservation Cancelled',
          body: /Reserver cancelled their reservation/,
          data: {
            type: 'reservation_cancelled',
            tee_time_id: tee_time.id,
            reservation_id: reservation.id
          },
          notification_type: :reservation_cancelled
        )

        ReservationNotificationJob.perform_now(reservation.id, action: 'cancelled')
      end
    end

    context 'when reservation does not exist' do
      it 'does not raise error' do
        expect {
          ReservationNotificationJob.perform_now(999999, action: 'created')
        }.not_to raise_error
      end

      it 'does not send notification' do
        expect(PushNotificationService).not_to receive(:send_to_user)

        ReservationNotificationJob.perform_now(999999, action: 'created')
      end
    end

    context 'when tee time does not exist' do
      it 'does not raise error' do
        reservation_id = reservation.id
        tee_time.destroy # This also destroys the reservation due to dependent: :destroy

        expect {
          ReservationNotificationJob.perform_now(reservation_id, action: 'created')
        }.not_to raise_error
      end

      it 'does not send notification' do
        reservation_id = reservation.id
        tee_time.destroy # This also destroys the reservation due to dependent: :destroy

        expect(PushNotificationService).not_to receive(:send_to_user)

        ReservationNotificationJob.perform_now(reservation_id, action: 'created')
      end
    end

    context 'with unknown action' do
      it 'logs warning and does not send notification' do
        expect(Rails.logger).to receive(:warn).with(/Unknown reservation action/)
        expect(PushNotificationService).not_to receive(:send_to_user)

        ReservationNotificationJob.perform_now(reservation.id, action: 'unknown')
      end
    end
  end
end
