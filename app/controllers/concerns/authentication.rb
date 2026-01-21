# frozen_string_literal: true

# Concern para gerenciar autenticação de usuários
module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def authenticate_user!
    return redirect_to login_path unless current_user
    
    @current_account = current_user.account
  end
end
