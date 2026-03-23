# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Gcm
  module Services
    class Ollama
      DEFAULT_MODEL = "gemma3"
      DEFAULT_URL = "http://localhost:11434"

      def initialize
        @model = ENV.fetch("OLLAMA_MODEL", DEFAULT_MODEL)
        @base_url = ENV.fetch("OLLAMA_URL", DEFAULT_URL)
      end

      def generate(prompt)
        uri = URI("#{@base_url}/api/generate")

        request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
        request.body = JSON.generate({
          model: @model,
          prompt: prompt,
          stream: false
        })

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.request(request)
        end

        case response
        when Net::HTTPSuccess
          data = JSON.parse(response.body)
          data.fetch("response").strip
        when Net::HTTPNotFound
          abort <<~MSG
            Error: Model '#{@model}' not found on the Ollama server
            To install #{@model}: ollama pull #{@model}
            Or set OLLAMA_MODEL environment variable to use a different model
          MSG
        else
          abort "Error from Ollama server: Status #{response.code}"
        end
      rescue Errno::ECONNREFUSED
        abort <<~MSG
          Error: Could not connect to Ollama server at #{@base_url}
          Please make sure the Ollama server is running
        MSG
      end
    end
  end
end
