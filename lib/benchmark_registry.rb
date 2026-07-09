require 'yaml'

class BenchmarkRegistry
  DEFAULT_PATH = File.expand_path('../ruby-bench/benchmarks.yml', __dir__)

  def initialize(path: DEFAULT_PATH)
    @path = path
  end

  def benchmarks
    return {} unless File.exist?(@path)

    benchmarks = YAML.safe_load_file(@path)
    return {} unless benchmarks.is_a?(Hash)

    benchmarks.reject { |name, metadata| filtered?(name, metadata) }
  rescue StandardError
    {}
  end

  def names
    benchmarks.keys
  end

  private

  def filtered?(name, metadata)
    metadata = {} unless metadata.respond_to?(:fetch)

    name.to_s.start_with?('ractor/') || metadata.fetch('ractor_only', false)
  end
end
