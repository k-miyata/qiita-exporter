# frozen_string_literal: true

require "fileutils"
require "pathname"

module QiitaExporter
  class DataStore
    class Location
      def initialize(path)
        @path = Pathname.new path
      end

      def +(other)
        self.class.new (@path + other.to_s).to_s
      end

      def -(other)
        self.class.new @path.relative_path_from other.to_s
      end

      def ==(other)
        @path == other.instance_variable_get(:@path)
      end

      def entries
        return [] unless @path.exist? && @path.directory?
        @path.children.map { |path| self.class.new path.to_s }
      end

      def eql?(other)
        instance_of?(other.class) && self == other
      end

      def exist?
        @path.exist?
      end

      def glob(pattern)
        @path.glob(pattern).map { |path| self.class.new path.to_s }
      end

      def hash
        [self.class, @path].hash
      end

      def inspect
        "#<#{self.class}:#{@path}>"
      end

      def read(name)
        path = @path.glob(name).first
        return nil unless path
        File.read path
      end

      def to_s
        @path.to_s
      end

      def write(name, data)
        FileUtils.mkdir_p @path unless @path.exist?
        File.write @path + name, data
      end
    end
  end
end
