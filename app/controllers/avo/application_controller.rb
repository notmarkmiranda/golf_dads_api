module Avo
  class ApplicationController < ::Avo::BaseApplicationController
    # Make current_user available from sessions
    # This is needed for Avo's current_user_method configuration
    def current_user
      return @current_user if defined?(@current_user)

      @current_user = if cookies.signed[:session_id]
        session = Session.find_by(id: cookies.signed[:session_id])
        session&.user
      end
    end
    helper_method :current_user
  end
end
