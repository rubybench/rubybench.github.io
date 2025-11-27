require_relative 'test_helper'
require 'benchmark_fetcher'

class BenchmarkFetcherTest < Minitest::Test
  def test_fetch_returns_nil_on_network_failure
    fetcher = BenchmarkFetcher.new(base_url: 'http://localhost:99999')

    result = fetcher.fetch('nonexistent')

    assert_nil result
  end

  def test_fetch_constructs_correct_url
    url_used = nil
    fetcher = BenchmarkFetcher.new(base_url: 'https://example.com/data')

    Open3.stub(:capture2, ->(*args) {
      url_used = args[4]
      ['', Struct.new(:success?).new(false)]
    }) do
      fetcher.fetch('my-benchmark')
    end

    assert_equal 'https://example.com/data/ruby-bench/my-benchmark.yml', url_used
  end

  def test_fetch_parses_yaml_response
    yaml_content = {'20251124' => [100, 50, 50]}.to_yaml
    success_status = Struct.new(:success?).new(true)

    Open3.stub(:capture2, [yaml_content, success_status]) do
      fetcher = BenchmarkFetcher.new
      result = fetcher.fetch('test')

      assert_equal({'20251124' => [100, 50, 50]}, result)
    end
  end

  def test_fetch_returns_nil_for_invalid_yaml
    success_status = Struct.new(:success?).new(true)

    Open3.stub(:capture2, ['not: valid: yaml: [', success_status]) do
      fetcher = BenchmarkFetcher.new
      result = fetcher.fetch('test')

      assert_nil result
    end
  end
end
