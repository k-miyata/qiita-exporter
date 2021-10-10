# frozen_string_literal: true

require "json"
require_relative "collection"
require_relative "resource"

module QiitaExporter
  class DataStore
    class Comment < Resource
      def attach
        @location.write "body.attached.md", attachments.to_a.inject(body) { |attached, attachment| attachment.attach_to attached, @location }
      end

      def attached_body
        @location.read "body.attached.md"
      end

      def attachments
        Collection.new @location + "attachments", :Attachment
      end

      def body
        @location.read "body.md"
      end

      def body=(value)
        @location.write "body.md", value
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
