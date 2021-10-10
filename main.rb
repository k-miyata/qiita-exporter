# frozen_string_literal: true

require "io/console"
require "open-uri"
require "uri"
require "qiita"
require_relative "lib/qiita_exporter/data_store"

print "Type your Qiita Team ID: "
TEAM = (t = gets.strip).empty? ? nil : t
print "Type your Qiita username: "
USER = (u = gets.strip).empty? ? nil : u
print "Type your access token with read access: "
TOKEN = STDIN.noecho(&:gets).strip; puts

TEAM_ATTACHMENTS_HOSTNAME = "#{TEAM}.qiita.com"
IMAGE_URL_PATTERN = "https:\/\/(?:qiita-image-store.s3.amazonaws.com|#{TEAM_ATTACHMENTS_HOSTNAME}\/files)\/.+"

qiita = Qiita::Client.new access_token: TOKEN, team: TEAM
store = QiitaExporter::DataStore.new "qiita_exports/#{TEAM}_#{USER}_#{Time.now.to_i}"

qiita_items_next_page = 1
qiita_items_last_page = nil

until qiita_items_next_page.nil? || qiita_items_next_page > 100
  puts "\e[90mGetting your posts on page #{qiita_items_next_page}#{" of #{qiita_items_last_page}" if qiita_items_last_page}...\e[m"
  qiita_items_params = { "page" => qiita_items_next_page, "per_page" => 100 }
  qiita_items = USER ? qiita.list_user_items(USER, qiita_items_params) : qiita.list_items(qiita_items_params)
  puts "\e[33m\e[1m#{qiita_items.headers["Rate-Remaining"]}\e[m\e[33m/#{qiita_items.headers["Rate-Limit"]} #{qiita_items.headers["Rate-Remaining"].to_i == 1 ? "request" : "requests"} remaining. The count will be reset at \e[1m#{Time.at qiita_items.headers["Rate-Reset"].to_i}\e[m\e[33m.\e[m"

  if qiita_items.status != 200
    puts "\e[31m#{qiita_items.body["message"]}\e[m"
    exit false
  end

  qiita_items_next_page = qiita_items.next_page_url.nil? ?
    nil :
    URI.decode_www_form(URI.parse(qiita_items.next_page_url).query).to_h["page"].to_i
  qiita_items_last_page = qiita_items.last_page_url.nil? ?
    nil :
    URI.decode_www_form(URI.parse(qiita_items.last_page_url).query).to_h["page"].to_i

  qiita_items.body.each do |qiita_item|
    puts "\e[34m#{qiita_item["id"]} - #{qiita_item["title"]}\e[m"

    item = store.items.new qiita_item["id"]
    item.body = qiita_item["body"]
    item.metadata = qiita_item.slice "id", "title", "created_at", "updated_at",
                                    "user", "team_membership", "tags", "url"

    images = item.body.scan /!\[.*\]\(#{IMAGE_URL_PATTERN}\)|<img\s.*src=["']#{IMAGE_URL_PATTERN}["'].*>/

    if images.empty?
      # puts "No images."
    else
      puts "#{images.size} #{images.size == 1 ? "image" : "images"} found."

      images.each do |image|
        alt = image.match(/!\[([^\[\]]*)\]|<img\s.*alt=["']([^"']+)["']/).to_a.compact[1]
        width = image.match(/<img\s.*width=["'](\d+)["']/)&.[](1)&.to_i
        url = URI.parse image.match(/!\[.*\]\(([^()]+)\)|<img\s.*src=["']([^"']+)["']/).to_a.compact[1]

        attachment = item.attachments.new File.basename url.path, ".*"
        attachment.metadata = { "alt" => alt, "width" => width, "url" => url }

        print "\e[90mDownloading #{url}...\e[m"
        if url.hostname == TEAM_ATTACHMENTS_HOSTNAME
          attachment.download url, 'authorization' => "Bearer #{TOKEN}"
        else
          attachment.download url
        end
        puts " Done."
      end

      item.attach
    end

    if qiita_item["comments_count"].zero?
      # puts "No comments."
    else
      puts "\e[90mGetting comments...\e[m"
      qiita_comments = qiita.list_item_comments item.metadata["id"], { "per_page" => 100 }
      puts "\e[33m\e[1m#{qiita_comments.headers["Rate-Remaining"]}\e[m\e[33m/#{qiita_comments.headers["Rate-Limit"]} #{qiita_comments.headers["Rate-Remaining"].to_i == 1 ? "request" : "requests"} remaining. The count will be reset at \e[1m#{Time.at qiita_comments.headers["Rate-Reset"].to_i}\e[m\e[33m.\e[m"

      if qiita_comments.status != 200
        puts "\e[31m#{qiita_comments.body["message"]}\e[m"
      elsif qiita_comments.body.empty?
        # puts "No comments."
      else
        puts "#{qiita_comments.body.size} #{qiita_comments.body.size == 1 ? "comment" : "comments"} found."

        qiita_comments.body.each do |qiita_comment|
          comment = item.comments.new qiita_comment["id"]
          comment.body = qiita_comment["body"]
          comment.metadata = qiita_comment.slice "id", "created_at", "updated_at",
                                                "user"

          images = comment.body.scan /!\[.*\]\(#{IMAGE_URL_PATTERN}\)|<img\s.*src=["']#{IMAGE_URL_PATTERN}["'].*>/

          if images.empty?
            # puts "No images."
          else
            puts "#{images.size} #{images.size == 1 ? "image" : "images"} found."

            images.each do |image|
              alt = image.match(/!\[([^\[\]]*)\]|<img\s.*alt=["']([^"']+)["']/).to_a.compact[1]
              width = image.match(/<img\s.*width=["'](\d+)["']/)&.[](1)&.to_i
              url = URI.parse image.match(/!\[.*\]\(([^()]+)\)|<img\s.*src=["']([^"']+)["']/).to_a.compact[1]

              attachment = comment.attachments.new File.basename url.path, ".*"
              attachment.metadata = { "alt" => alt, "width" => width, "url" => url }

              print "\e[90mDownloading #{url}...\e[m"
              if url.hostname == TEAM_ATTACHMENTS_HOSTNAME
                attachment.download url, 'authorization' => "Bearer #{TOKEN}"
              else
                attachment.download url
              end
              puts " Done."
            end

            comment.attach
          end
        end
      end
    end
  end
end

puts "\e[32mSuccessfully saved your posts to #{store.location}.\e[m"
