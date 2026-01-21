# frozen_string_literal: true

module Backoffice
  class BaseController < ApplicationController
        layout "backoffice"

    before_action :authenticate_user!
    before_action :authorize_resource, if: -> { action_name != "index" }

    helper_method :current_account

    private

    def pundit_user
      current_user
    end

    # Sobrescreve policy para sempre usar BackofficePolicy para controllers backoffice
    def policy(record)
      BackofficePolicy.new(pundit_user, record)
    end

    # Autoriza automaticamente o recurso se existir
    def authorize_resource
      resource = instance_variable_get("@#{controller_name.singularize}")
      authorize(resource) if resource.present?
    end

    def current_account
      @current_account ||= current_user&.account
    end
  end
end
