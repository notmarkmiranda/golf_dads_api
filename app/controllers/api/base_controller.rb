module Api
  class BaseController < ActionController::API
    # API-only controller - no sessions, cookies, or CSRF protection needed
  end
end
