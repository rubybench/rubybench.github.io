require_relative 'test_helper'
require 'benchmark_registry'
require 'tempfile'
require 'yaml'

class BenchmarkRegistryTest < Minitest::Test
  def test_names_returns_benchmark_names
    with_benchmarks_file({'bench1' => {}, 'bench2' => {}}) do |path|
      registry = BenchmarkRegistry.new(path: path)

      result = registry.names

      assert_includes result, 'bench1'
      assert_includes result, 'bench2'
    end
  end

  def test_names_filters_out_ractor_benchmarks
    with_benchmarks_file({'regular' => {}, 'ractor/test' => {}}) do |path|
      registry = BenchmarkRegistry.new(path: path)

      result = registry.names

      assert_includes result, 'regular'
      refute_includes result, 'ractor/test'
    end
  end

  def test_names_returns_empty_array_if_file_missing
    registry = BenchmarkRegistry.new(path: '/nonexistent/path.yml')

    result = registry.names

    assert_equal [], result
  end

  def test_names_returns_empty_array_for_invalid_yaml
    Tempfile.create(['benchmarks', '.yml']) do |file|
      file.write("not: valid: yaml: [")
      file.close

      registry = BenchmarkRegistry.new(path: file.path)

      result = registry.names

      assert_equal [], result
    end
  end

  private

  def with_benchmarks_file(content)
    Tempfile.create(['benchmarks', '.yml']) do |file|
      file.write(content.to_yaml)
      file.close
      yield file.path
    end
  end
end
