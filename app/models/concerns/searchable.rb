# frozen_string_literal: true

module Searchable
  extend ActiveSupport::Concern

  included do
    scope :search, ->(term) {
      return all if term.blank?
      return all if searchable_columns.blank?

      search_term = "%#{term.strip}%"
      conditions = searchable_columns.map { |col|
        "#{table_name}.#{col} ILIKE ?"
      }.join(" OR ")

      where(conditions, *([search_term] * searchable_columns.count))
    }
  end

  class_methods do
    attr_accessor :searchable_columns

    def searchable_columns(*columns)
      @searchable_columns = columns.map(&:to_s)
    end
  end
end
