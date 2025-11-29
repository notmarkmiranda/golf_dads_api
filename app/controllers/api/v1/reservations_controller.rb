module Api
  module V1
    class ReservationsController < Api::BaseController
      before_action :set_reservation, only: [:show, :update, :destroy]

      # GET /api/v1/reservations
      def index
        authorize Reservation
        @reservations = policy_scope(Reservation)
        render json: { reservations: @reservations }, status: :ok
      end

      # GET /api/v1/reservations/:id
      def show
        authorize @reservation
        render json: { reservation: @reservation }, status: :ok
      end

      # POST /api/v1/reservations
      def create
        authorize Reservation
        @reservation = current_user.reservations.build(reservation_params)

        if @reservation.save
          render json: { reservation: @reservation }, status: :created
        else
          validation_error_response(@reservation.errors.messages)
        end
      end

      # PATCH/PUT /api/v1/reservations/:id
      def update
        authorize @reservation

        if @reservation.update(reservation_params)
          render json: { reservation: @reservation }, status: :ok
        else
          validation_error_response(@reservation.errors.messages)
        end
      end

      # DELETE /api/v1/reservations/:id
      def destroy
        authorize @reservation
        @reservation.destroy
        head :no_content
      end

      # GET /api/v1/reservations/my_reservations
      def my_reservations
        authorize Reservation
        @reservations = policy_scope(Reservation).where(user_id: current_user.id)
        render json: { reservations: @reservations }, status: :ok
      end

      private

      def set_reservation
        @reservation = Reservation.find(params[:id])
      end

      def reservation_params
        params.require(:reservation).permit(:tee_time_posting_id, :spots_reserved)
      end
    end
  end
end
