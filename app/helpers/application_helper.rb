# frozen_string_literal: true

module ApplicationHelper
  def decorate(object)
    return nil if object.nil?

    decorator_class = "#{object.class.name}Decorator".constantize
    decorator_class.decorate(object)
  rescue NameError
    object
  end
end
