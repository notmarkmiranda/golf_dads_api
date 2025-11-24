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
          render json: { errors: @reservation.errors.messages }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/reservations/:id
      def update
        authorize @reservation

        if @reservation.update(reservation_params)
          render json: { reservation: @reservation }, status: :ok
        else
          render json: { errors: @reservation.errors.messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/reservations/:id
      def destroy
        authorize @reservation
        @reservation.destroy
        head :no_content
      end

      private

      def set_reservation
        @reservation = Reservation.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Reservation not found' }, status: :not_found
      end

      def reservation_params
        params.require(:reservation).permit(:tee_time_posting_id, :spots_reserved)
      end
    end
  end
end
