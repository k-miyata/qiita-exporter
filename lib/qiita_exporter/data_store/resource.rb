# frozen_string_literal: true

module QiitaExporter
  class DataStore
    class Resource
      def initialize(location)
        @location = location
      end

      def ==(other)
        @location == other.instance_variable_get(:@location)
      end

      def eql?(other)
        instance_of?(other.class) && self == other
      end

      def hash
        [self.class, @location].hash
      end

      def inspect
        "#<#{self.class}:#{@location}>"
      end
    end
  end
end
