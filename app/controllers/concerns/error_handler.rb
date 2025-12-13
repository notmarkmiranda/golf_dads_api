module ErrorHandler
  extend ActiveSupport::Concern

  included do
    # Handle Pundit authorization errors
    rescue_from Pundit::NotAuthorizedError, with: :handle_unauthorized

    # Handle ActiveRecord errors
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid

    # Handle parameter errors
    rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  end

  private

  # Standardized error response format
  def error_response(message:, status:, details: nil)
    response = { error: message }
    response[:details] = details if details.present?
    render json: response, status: status
  end

  # Standardized validation error response format
  def validation_error_response(errors)
    render json: { errors: errors }, status: :unprocessable_content
  end

  # Handle Pundit authorization errors (403 Forbidden or 401 Unauthorized)
  def handle_unauthorized(exception)
    if current_user.nil?
      error_response(
        message: "Unauthorized",
        status: :unauthorized
      )
    else
      error_response(
        message: "You are not authorized to perform this action",
        status: :forbidden
      )
    end
  end

  # Handle record not found errors (404 Not Found)
  def handle_not_found(exception)
    # Convert model class name to human-readable format
    # e.g., "TeeTimePosting" -> "Tee time posting"
    model_name = exception.model.constantize.model_name.human.downcase
    error_response(
      message: "#{model_name.capitalize} not found",
      status: :not_found
    )
  end

  # Handle record invalid errors (422 Unprocessable Content)
  def handle_record_invalid(exception)
    validation_error_response(exception.record.errors.messages)
  end

  # Handle missing parameter errors (400 Bad Request)
  def handle_parameter_missing(exception)
    error_response(
      message: "Required parameter is missing",
      status: :bad_request,
      details: { parameter: exception.param }
    )
  end
end
