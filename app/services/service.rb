# frozen_string_literal: true

# Classe base para todos os services
# Fornece funcionalidades comuns:
# - ActiveModel::Model para integração com errors
# - Métodos auxiliares para validações comuns
# - Métodos auxiliares para tratamento de erros de models
# - Método helper para executar em transação com tratamento de erros
class Service
  include ActiveModel::Model
  attr_reader :errors

  def initialize(**kwargs)
    super(**kwargs) if defined?(super)
    @errors ||= ActiveModel::Errors.new(self)
  end

  private

  # Helper para executar código dentro de uma transação com tratamento de erros
  def execute_with_transaction
    ActiveRecord::Base.transaction do
      yield
    end
    true
  rescue StandardError => e
    errors.add(:base, e.message)
    false
  end

  # Validação: Verifica se um atributo está presente
  def validate_presence(attribute, value, message: nil)
    return true if value.present?

    error_message = message || "#{attribute} não pode ficar em branco"
    errors.add(attribute, error_message)
    false
  end

  # Validação: Verifica se um atributo está presente em uma lista de valores
  def validate_inclusion(attribute, value, in: [], message: nil)
    return true if value.in?(binding.local_variable_get(:in))

    error_message = message || "#{attribute} deve estar em #{binding.local_variable_get(:in).join(', ')}"
    errors.add(attribute, error_message)
    false
  end

  # Validação: Verifica se um objeto (model) é válido e adiciona seus erros
  def validate_model(model, context: nil)
    return true if model.valid?(context)

    model.errors.each do |error|
      errors.add(error.attribute, error.message)
    end
    false
  end

  # Validação: Verifica se uma condição é verdadeira
  def validate_condition(condition, attribute: :base, message:)
    return true if condition

    errors.add(attribute, message)
    false
  end

  # Validação: Verifica se um objeto existe e está ativo (se tiver método active?)
  def validate_active(object, attribute: :base, message: nil)
    return true if object.blank? # Permite nil
    return true if object.respond_to?(:active?) && object.active?
    return true unless object.respond_to?(:active?)

    error_message = message || "#{object.class.name} não está ativo"
    errors.add(attribute, error_message)
    false
  end

  # Validação: Verifica se um usuário tem permissão para uma ação
  def validate_permission(user, action, resource, message: nil)
    return true if user.blank? # Deixa Pundit lidar com nil
    return true if BackofficePolicy.new(user, resource).public_send("#{action}?")

    error_message = message || "Você não tem permissão para #{action} este recurso"
    errors.add(:base, error_message)
    false
  end

  # Helper: Salva um model e adiciona erros ao service se falhar
  def save_model!(model, raise_on_error: false)
    if model.save
      true
    else
      model.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
      raise ActiveRecord::Rollback if raise_on_error
      false
    end
  end

  # Helper: Atualiza um model e adiciona erros ao service se falhar
  def update_model!(model, attributes, raise_on_error: false)
    if model.update(attributes)
      true
    else
      model.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
      raise ActiveRecord::Rollback if raise_on_error
      false
    end
  end

  # Helper: Cria um model e adiciona erros ao service se falhar
  def create_model!(association, attributes, raise_on_error: false)
    model = association.build(attributes)

    if model.save
      model
    else
      model.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
      raise ActiveRecord::Rollback if raise_on_error
      nil
    end
  end

  # Helper: Destrói um model e adiciona erros ao service se falhar
  def destroy_model!(model, raise_on_error: false)
    if model.destroy
      true
    else
      errors.add(:base, "Não foi possível excluir o recurso")
      raise ActiveRecord::Rollback if raise_on_error
      false
    end
  end
end
