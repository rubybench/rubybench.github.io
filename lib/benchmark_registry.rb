require 'yaml'

class BenchmarkRegistry
  DEFAULT_PATH = File.expand_path('../ruby-bench/benchmarks.yml', __dir__)

  def initialize(path: DEFAULT_PATH)
    @path = path
  end

  def names
    return [] unless File.exist?(@path)
    benchmarks = YAML.safe_load_file(@path)
    benchmarks.keys.reject { |name| name.to_s.start_with?('ractor/') }
  rescue StandardError
    []
  end
end
