# frozen_string_literal: true

class SessionsController < ApplicationController
  layout "auth"
  skip_before_action :authenticate_user!, only: [:new, :create]

  def new
    redirect_to backoffice_root_path if current_user
  end

  def create
    user = User.find_by(email: params[:email]&.downcase&.strip)
    
    if user&.authenticate(params[:password]) && user.active?
      session[:user_id] = user.id
      redirect_to backoffice_root_path, notice: "Bem-vindo de volta!"
    else
      flash.now[:alert] = "E-mail ou senha inválidos"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: "Você saiu com sucesso"
  end
end
