# frozen_string_literal: true

class ApplicationDecorator
  extend ActiveSupport::Concern

  attr_reader :object

  def initialize(object)
    @object = object
  end

  def self.decorate(object)
    return object if object.is_a?(self)
    return nil if object.nil?

    new(object)
  end

  def self.decorate_collection(collection)
    collection.map { |item| decorate(item) }
  end

  # Delegate all methods to the object
  # This is called in subclasses with delegate_all
  def self.delegate_all
    # This will be implemented by subclasses
    # The actual delegation happens via method_missing
  end

  # Delegate all methods to the object using method_missing
  # This allows decorators to automatically delegate all object methods
  def method_missing(method, *args, &block)
    if object.respond_to?(method)
      object.public_send(method, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(method, include_private = false)
    object.respond_to?(method, include_private) || super
  end
end
