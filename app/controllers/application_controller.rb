class ApplicationController < ActionController::Base
  before_action :basic_auth
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  private

  def basic_auth
    if Rails.env.production?
      authenticate_or_request_with_http_basic do |username, password|
        # credentials から値を取得
        username == Rails.application.credentials.dig(:basic_auth, :username) &&
        password == Rails.application.credentials.dig(:basic_auth, :password)
      end
    end
  end
end