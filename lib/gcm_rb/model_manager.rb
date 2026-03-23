# frozen_string_literal: true

require "net/http"
require "uri"
require "fileutils"

module GcmRb
  module ModelManager
    GITHUB_REPO = "n-at-han-k/gcm.rb"

    MODELS = {
      "smollm2-135m" => {
        url: "https://huggingface.co/prithivMLmods/SmolLM2-135M-Instruct-GGUF/resolve/main/SmolLM2-135M-Instruct.Q4_K_M.gguf",
        file: "SmolLM2-135M-Instruct.Q4_K_M.gguf"
      },
      "qwen2.5-coder-0.5b" => {
        url: "https://huggingface.co/bartowski/Qwen2.5-Coder-0.5B-Instruct-GGUF/resolve/main/Qwen2.5-Coder-0.5B-Instruct-Q4_0.gguf",
        file: "Qwen2.5-Coder-0.5B-Instruct-Q4_0.gguf"
      },
      "qwen2.5-coder-0.5b-q8" => {
        url: "https://huggingface.co/bartowski/Qwen2.5-Coder-0.5B-Instruct-GGUF/resolve/main/Qwen2.5-Coder-0.5B-Instruct-Q8_0.gguf",
        file: "Qwen2.5-Coder-0.5B-Instruct-Q8_0.gguf"
      }
    }.freeze

    DEFAULT_MODEL = "smollm2-135m"

    def self.data_dir
      base = ENV.fetch("XDG_DATA_HOME", File.join(Dir.home, ".local", "share"))
      File.join(base, "gcm_rb")
    end

    def self.models_dir
      File.join(data_dir, "models")
    end

    def self.bin_dir
      File.join(data_dir, "bin")
    end

    def self.model_name
      ENV.fetch("GCM_MODEL", DEFAULT_MODEL)
    end

    def self.model_path
      name = model_name

      # If it's an absolute path to a .gguf file, use it directly
      return name if name.end_with?(".gguf") && File.exist?(name)

      model = MODELS.fetch(name) do
        abort "Error: unknown model '#{name}'. Available: #{MODELS.keys.join(', ')}"
      end

      File.join(models_dir, model[:file])
    end

    def self.ensure_model!
      path = model_path
      return path if File.exist?(path)

      name = model_name
      model = MODELS[name]
      abort "Error: unknown model '#{name}'" unless model

      FileUtils.mkdir_p(models_dir)
      warn "Downloading model #{name} (#{model[:file]})..."
      download(model[:url], path)
      warn "Model saved to #{path}"
      path
    end

    def self.llama_cli_path
      # Check override
      custom = ENV["GCM_LLAMA_PATH"]
      return custom if custom && File.executable?(custom)

      # Check our managed binary
      managed = File.join(bin_dir, "llama-cli")
      return managed if File.executable?(managed)

      # Check PATH
      system_path = which("llama-cli")
      return system_path if system_path

      nil
    end

    def self.ensure_llama_cli!
      path = llama_cli_path
      return path if path

      FileUtils.mkdir_p(bin_dir)
      dest = File.join(bin_dir, "llama-cli")

      arch = detect_arch
      url = latest_llama_cli_url(arch)

      warn "Downloading llama-cli for #{arch}..."
      download(url, dest)
      File.chmod(0o755, dest)
      warn "llama-cli saved to #{dest}"
      dest
    end

    def self.detect_arch
      machine = `uname -m`.strip
      kernel = `uname -s`.strip.downcase

      case [machine, kernel]
      when ["x86_64", "linux"] then "x86_64-linux"
      when ["aarch64", "linux"] then "aarch64-linux"
      else
        abort "Error: unsupported platform #{machine}-#{kernel}. Build llama-cli manually and set GCM_LLAMA_PATH."
      end
    end

    def self.latest_llama_cli_url(arch)
      # Fetch latest release with a llama- tag from our repo
      uri = URI("https://api.github.com/repos/#{GITHUB_REPO}/releases")
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        req = Net::HTTP::Get.new(uri)
        req["Accept"] = "application/vnd.github+json"
        http.request(req)
      end

      unless response.is_a?(Net::HTTPSuccess)
        abort "Error: failed to fetch releases from #{GITHUB_REPO}: #{response.code}"
      end

      releases = JSON.parse(response.body)
      release = releases.find { |r| r["tag_name"]&.start_with?("llama-") }
      abort "Error: no llama-cli release found on #{GITHUB_REPO}. Run the build-llama-cli workflow first." unless release

      asset_name = "llama-cli-#{arch}"
      asset = release["assets"]&.find { |a| a["name"] == asset_name }
      abort "Error: no #{asset_name} asset in release #{release['tag_name']}" unless asset

      asset["browser_download_url"]
    end

    def self.download(url, dest)
      uri = URI(url)
      tmp = "#{dest}.tmp"

      begin
        Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
          request = Net::HTTP::Get.new(uri)
          http.request(request) do |response|
            case response
            when Net::HTTPRedirection
              return download(response["location"], dest)
            when Net::HTTPSuccess
              File.open(tmp, "wb") do |file|
                response.read_body do |chunk|
                  file.write(chunk)
                end
              end
            else
              abort "Error: download failed (#{response.code}) from #{url}"
            end
          end
        end

        FileUtils.mv(tmp, dest)
      rescue StandardError => e
        FileUtils.rm_f(tmp)
        abort "Error: download failed: #{e.message}"
      end
    end

    def self.which(cmd)
      ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).each do |dir|
        path = File.join(dir, cmd)
        return path if File.executable?(path) && !File.directory?(path)
      end
      nil
    end
  end
end
