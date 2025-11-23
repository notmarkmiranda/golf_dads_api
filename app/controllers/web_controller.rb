class WebController < ActionController::Base
  include Authentication

  # Base controller for session-based authentication (Avo admin, sessions, passwords)
  # Inherits from ActionController::Base to support views, sessions, and helper methods
end
