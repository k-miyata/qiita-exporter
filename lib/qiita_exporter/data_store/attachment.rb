# frozen_string_literal: true

require "json"
require "open-uri"
require_relative "resource"

module QiitaExporter
  class DataStore
    class Attachment < Resource
      def attach_to(resource_data, resource_location)
        data_location = @location.glob("data.*").first
        return nil unless data_location
        resource_data.gsub metadata["url"], (data_location - resource_location).to_s
      end

      def data
        @location.read "data.*"
      end

      def download(url, *header_fields)
        open url, *header_fields do |remote_file|
          @location.write "data#{File.extname url.path}", remote_file.read
        end
      end

      def metadata
        JSON.parse @location.read "metadata.json"
      end

      def metadata=(value)
        @location.write "metadata.json", JSON.pretty_generate(value)
      end
    end
  end
end
