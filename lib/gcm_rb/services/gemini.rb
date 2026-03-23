# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module GcmRb
  module Services
    class Gemini
      API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent"

      def initialize
        @api_key = ENV.fetch("GEMINI_API_KEY") do
          abort "GEMINI_API_KEY environment variable not set"
        end
      end

      def generate(prompt)
        uri = URI("#{API_URL}?key=#{@api_key}")

        request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
        request.body = JSON.generate({
          contents: [{
            parts: [{ text: prompt }]
          }]
        })

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end

        unless response.is_a?(Net::HTTPSuccess)
          abort "Error from Gemini server: Status #{response.code}"
        end

        data = JSON.parse(response.body)
        data.dig("candidates", 0, "content", "parts", 0, "text")&.strip ||
          abort("Error: unexpected response format from Gemini")
      end
    end
  end
end
