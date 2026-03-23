# frozen_string_literal: true

require_relative "gcm/prompt"
require_relative "gcm/services/ollama"
require_relative "gcm/services/gemini"

module Gcm
  def self.run
    diff = $stdin.read

    if diff.nil? || diff.strip.empty?
      warn "No git diff provided on stdin"
      exit 1
    end

    prompt = Prompt.build(diff)

    service = if ENV["GEMINI_API_KEY"]
                Services::Gemini.new
              else
                Services::Ollama.new
              end

    puts service.generate(prompt)
  end
end
