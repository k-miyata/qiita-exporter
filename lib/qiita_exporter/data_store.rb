# frozen_string_literal: true

require_relative "data_store/collection"
require_relative "data_store/location"

module QiitaExporter
  class DataStore
    def initialize(location)
      @location = Location.new location
    end

    def items
      Collection.new @location + "items", :Item
    end

    def location
      @location.to_s
    end
  end
end
