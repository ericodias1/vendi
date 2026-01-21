# frozen_string_literal: true

class PasswordResetsController < ApplicationController
  layout "auth"
  skip_before_action :authenticate_user!

  def new
  end

  def create
    user = User.find_by(email: params[:email]&.downcase&.strip)
    
    if user
      user.generate_password_reset_token!
      PasswordResetMailer.reset_password(user).deliver_now
    end
    redirect_to login_path, notice: "Instruções para redefinir sua senha foram enviadas para seu e-mail"
  end

  def edit
    @user = User.find_by(password_reset_token: params[:token])
    
    unless @user&.password_reset_token_valid?
      redirect_to login_path, alert: "Link de recuperação inválido ou expirado"
    end
  end

  def update
    @user = User.find_by(password_reset_token: params[:token])
    
    unless @user&.password_reset_token_valid?
      redirect_to login_path, alert: "Link de recuperação inválido ou expirado"
      return
    end

    if @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      @user.clear_password_reset_token!
      redirect_to login_path, notice: "Senha redefinida com sucesso! Faça login com sua nova senha"
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
