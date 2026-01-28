# frozen_string_literal: true

# Concern para gerenciar autenticação de usuários
module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :current_account, :impersonating_account?
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def current_account
    return @current_account if defined?(@current_account)

    return nil unless current_user

    # Para usuários admin, permite impersonar uma outra account via sessão
    if current_user.respond_to?(:admin?) && current_user.admin? && session[:impersonated_account_id].present?
      account = Account.find_by(id: session[:impersonated_account_id])

      if account&.active?
        @current_account = account
      else
        # Se a conta não existir mais ou não estiver ativa, limpa a sessão e volta para a conta padrão do usuário
        session.delete(:impersonated_account_id)
        @current_account = current_user.account
      end
    else
      @current_account = current_user.account
    end
  end

  def impersonating_account?
    current_user&.admin? && session[:impersonated_account_id].present?
  end

  def authenticate_user!
    return redirect_to login_path unless current_user

    # Garante que current_account seja resolvida e que qualquer sessão inválida seja limpa
    current_account
  end
end
