# frozen_string_literal: true

class RegistrationsController < ApplicationController
  layout "auth"
  skip_before_action :authenticate_user!

  def new
    redirect_to backoffice_root_path if current_user
    @form = RegistrationForm.new
  end

  def create
    @form = RegistrationForm.new(registration_params)
    service = Backoffice::Accounts::CreateService.new(form: @form)
    
    if service.call
      session[:user_id] = service.user.id
      redirect_to backoffice_root_path, notice: "Conta criada com sucesso! Bem-vindo ao Vendi Gestão."
    else
      # Adiciona erros do service ao form
      service.errors.each do |error|
        @form.errors.add(error.attribute, error.message) unless @form.errors[error.attribute].include?(error.message)
      end
      
      flash.now[:alert] = "Erro ao criar conta. Verifique os campos abaixo."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:registration_form).permit(
      # Account fields
      :account_name,
      :whatsapp,
      # User fields
      :name,
      :email,
      :password,
      :password_confirmation
    )
  end
end
