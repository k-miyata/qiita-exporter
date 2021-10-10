# frozen_string_literal: true

module QiitaExporter
  class DataStore
    class Collection
      def initialize(location, type)
        @location = location
        require_relative type.to_s.downcase
        @Type = DataStore.const_get type
      end

      def [](index)
        to_a[index]
      end

      def first
        to_a.first
      end

      def last
        to_a.last
      end

      def new(id)
        @Type.new @location + id
      end

      def to_a
        @location.entries.map { |location| @Type.new location }
      end
    end
  end
end
