require 'yaml'
require 'open3'

class BenchmarkFetcher
  DEFAULT_BASE_URL = 'https://raw.githubusercontent.com/rubybench/rubybench-data/main'

  def initialize(base_url: DEFAULT_BASE_URL)
    @base_url = base_url
  end

  def fetch(benchmark_name)
    url = "#{@base_url}/ruby-bench/#{benchmark_name}.yml"
    stdout, status = Open3.capture2('curl', '-sf', '--max-time', '10', url)
    return nil unless status.success?
    YAML.safe_load(stdout)
  rescue StandardError
    nil
  end
end
