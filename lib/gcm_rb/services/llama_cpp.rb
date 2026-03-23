# frozen_string_literal: true

require "tempfile"
require "open3"
require_relative "../model_manager"

module GcmRb
  module Services
    class LlamaCpp
      def initialize
        @llama_cli = ModelManager.ensure_llama_cli!
        @model_path = ModelManager.ensure_model!
      end

      def generate(prompt)
        Tempfile.create(["gcm-prompt", ".txt"]) do |f|
          f.write(prompt)
          f.flush

          cmd = [
            @llama_cli,
            "-m", @model_path,
            "-f", f.path,
            "-n", "256",
            "--no-display-prompt",
            "--temp", "0.3",
            "--log-disable"
          ]

          stdout, stderr, status = Open3.capture3(*cmd)

          unless status.success?
            abort "Error: llama-cli failed (exit #{status.exitstatus})\n#{stderr}"
          end

          stdout.strip
        end
      end
    end
  end
end
