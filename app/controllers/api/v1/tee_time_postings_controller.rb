module Api
  module V1
    class TeeTimePostingsController < Api::BaseController
      before_action :set_tee_time_posting, only: [ :show, :update, :destroy ]

      # GET /api/v1/tee_time_postings
      # Optional params: latitude, longitude, radius (for location-based filtering)
      def index
        authorize TeeTimePosting
        # Only show tee times from last 6 hours onwards (hide old past tee times)
        @tee_time_postings = policy_scope(TeeTimePosting).recent

        # Apply location filter if coordinates provided
        latitude = params[:latitude]&.to_f
        longitude = params[:longitude]&.to_f
        radius = params[:radius]&.to_i

        if latitude && longitude
          radius ||= current_user.preferred_radius_miles || 25
          # Get the IDs from policy_scope first, then apply near scope separately
          # This avoids the DISTINCT + ORDER BY conflict
          authorized_ids = @tee_time_postings.pluck(:id)
          @tee_time_postings = TeeTimePosting
            .where(id: authorized_ids)
            .near(
              latitude: latitude,
              longitude: longitude,
              radius_miles: radius
            )
        end

        render json: {
          tee_time_postings: @tee_time_postings.map { |ttp|
            ttp.as_json(
              current_user: current_user,
              latitude: latitude,
              longitude: longitude
            )
          }
        }, status: :ok
      end

      # GET /api/v1/tee_time_postings/:id
      def show
        authorize @tee_time_posting
        render json: { tee_time_posting: @tee_time_posting.as_json(current_user: current_user) }, status: :ok
      end

      # POST /api/v1/tee_time_postings
      def create
        authorize TeeTimePosting
        @tee_time_posting = current_user.tee_time_postings.build(tee_time_posting_params)

        ActiveRecord::Base.transaction do
          if @tee_time_posting.save
            # Create initial reservation if requested
            if params[:initial_reservation_spots].present? && params[:initial_reservation_spots].to_i > 0
              reservation = @tee_time_posting.reservations.create!(
                user: current_user,
                spots_reserved: params[:initial_reservation_spots].to_i
              )
            end

            render json: { tee_time_posting: @tee_time_posting.as_json(current_user: current_user) }, status: :created
          else
            validation_error_response(@tee_time_posting.errors.messages)
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        validation_error_response(e.record.errors.messages)
      end

      # PATCH/PUT /api/v1/tee_time_postings/:id
      def update
        authorize @tee_time_posting

        if @tee_time_posting.update(tee_time_posting_params)
          render json: { tee_time_posting: @tee_time_posting.as_json(current_user: current_user) }, status: :ok
        else
          validation_error_response(@tee_time_posting.errors.messages)
        end
      end

      # DELETE /api/v1/tee_time_postings/:id
      def destroy
        authorize @tee_time_posting
        @tee_time_posting.destroy
        head :no_content
      end

      # GET /api/v1/tee_time_postings/my_postings
      def my_postings
        authorize TeeTimePosting
        # Only show tee times from last 6 hours onwards, ordered by soonest first
        @tee_time_postings = policy_scope(TeeTimePosting)
          .where(user_id: current_user.id)
          .where("tee_time > ?", 6.hours.ago)
          .order(tee_time: :asc)
        render json: { tee_time_postings: @tee_time_postings }, status: :ok
      end

      private

      def set_tee_time_posting
        @tee_time_posting = TeeTimePosting.find(params[:id])
      end

      def tee_time_posting_params
        params.require(:tee_time_posting).permit(:tee_time, :course_name, :golf_course_id, :total_spots, :notes, group_ids: [])
      end
    end
  end
end
