# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!

  layout :layout_by_resource

  def layout_by_resource
    if request.path.start_with?("/backoffice")
      "backoffice"
    elsif controller_name == "sessions" || controller_name == "password_resets"
      "auth"
    else
      "application"
    end
  end
end
