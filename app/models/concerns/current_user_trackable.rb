# frozen_string_literal: true

# Concern para permitir que models acessem current_user em callbacks
# Uso: include CurrentUserTrackable no model
# Depois, no controller: Model.set_current_user(current_user) antes de salvar
module CurrentUserTrackable
  extend ActiveSupport::Concern

  included do
    class_attribute :_current_user, instance_writer: false
  end

  class_methods do
    def set_current_user(user)
      self._current_user = user
    end

    def current_user
      _current_user
    end
  end

  def current_user
    self.class.current_user
  end
end
