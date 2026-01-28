# frozen_string_literal: true

module Backoffice
  class BaseController < ApplicationController
    layout "backoffice"

    before_action :authenticate_user!
    before_action :ensure_onboarding_completed!
    before_action :authorize_resource, if: -> { action_name != "index" }

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

    def ensure_onboarding_completed!
      return if current_account.blank?
      return if current_account.onboarding_completed_at.present?

      # Não bloquear o próprio fluxo de onboarding
      return if controller_name == "onboarding"

      redirect_to backoffice_onboarding_path, alert: "Vamos finalizar a configuração da sua loja antes de continuar."
    end
  end
end
