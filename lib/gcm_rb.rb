# frozen_string_literal: true

require_relative "gcm_rb/version"
require_relative "gcm_rb/prompt"
require_relative "gcm_rb/services/llama_cpp"
require_relative "gcm_rb/services/ollama"
require_relative "gcm_rb/services/gemini"

module GcmRb
  def self.run
    diff = $stdin.read

    if diff.nil? || diff.strip.empty?
      warn "No git diff provided on stdin"
      exit 1
    end

    prompt = Prompt.build(diff)

    service = if ENV["GEMINI_API_KEY"]
                Services::Gemini.new
              elsif ENV["OLLAMA_MODEL"] || ENV["OLLAMA_URL"]
                Services::Ollama.new
              else
                Services::LlamaCpp.new
              end

    puts service.generate(prompt)
  end
end
