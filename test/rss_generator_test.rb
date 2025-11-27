require_relative 'test_helper'
require 'rss_generator'

class RSSGeneratorTest < Minitest::Test
  def setup
    @registry = MockRegistry.new
    @calculator = MockCalculator.new
    @analyzer = WeeklyAnalyzer.new
    @generator = RSSGenerator.new(
      registry: @registry,
      calculator: @calculator,
      analyzer: @analyzer
    )
  end

  def test_generate_entry_returns_nil_when_no_benchmarks
    @registry.benchmark_names = []

    result = @generator.generate_entry(Date.new(2025, 11, 24))

    assert_nil result
  end

  def test_generate_entry_returns_nil_when_current_week_has_no_data
    @registry.benchmark_names = ['bench1']
    @calculator.speedups = {}

    result = @generator.generate_entry(Date.new(2025, 11, 24))

    assert_nil result
  end

  def test_generate_entry_returns_correct_structure
    @registry.benchmark_names = ['bench1']
    @calculator.speedups = {
      Date.new(2025, 11, 24) => {'bench1' => 2.0},
      Date.new(2025, 11, 17) => {'bench1' => 1.5}
    }

    result = @generator.generate_entry(Date.new(2025, 11, 24))

    assert_equal '2025-11-24', result['week_beginning']
    assert_equal 'rubybench-week-2025-11-24', result['guid']
    assert_equal 'https://rubybench.github.io/', result['link']
    assert result.key?('zjit')
  end

  def test_generate_entry_includes_zjit_data
    @registry.benchmark_names = ['bench1']
    @calculator.speedups = {
      Date.new(2025, 11, 24) => {'bench1' => 2.0},
      Date.new(2025, 11, 17) => {'bench1' => 1.5}
    }

    result = @generator.generate_entry(Date.new(2025, 11, 24))
    zjit = result['zjit']

    assert_equal 2.0, zjit['current_speedup']
    assert_equal 1.5, zjit['previous_speedup']
    assert_kind_of Numeric, zjit['change_pct']
    assert_kind_of Array, zjit['improvements']
    assert_kind_of Array, zjit['regressions']
  end

  def test_generate_entry_fetches_previous_week_data
    @registry.benchmark_names = ['bench1']
    @calculator.speedups = {
      Date.new(2025, 11, 24) => {'bench1' => 2.0},
      Date.new(2025, 11, 17) => {'bench1' => 1.0}
    }

    @generator.generate_entry(Date.new(2025, 11, 24))

    assert_includes @calculator.dates_requested, Date.new(2025, 11, 24)
    assert_includes @calculator.dates_requested, Date.new(2025, 11, 17)
  end

  def test_generate_entry_formats_improvements_correctly
    @registry.benchmark_names = ['improved']
    @calculator.speedups = {
      Date.new(2025, 11, 24) => {'improved' => 2.0},
      Date.new(2025, 11, 17) => {'improved' => 1.0}
    }

    result = @generator.generate_entry(Date.new(2025, 11, 24))
    improvement = result['zjit']['improvements'].first

    assert_equal 'improved', improvement['name']
    assert_equal 2.0, improvement['current']
    assert_equal 1.0, improvement['previous']
    assert_equal 100.0, improvement['change']
  end

  class MockRegistry
    attr_accessor :benchmark_names

    def initialize
      @benchmark_names = []
    end

    def names
      @benchmark_names
    end
  end

  class MockCalculator
    attr_accessor :speedups, :dates_requested

    def initialize
      @speedups = {}
      @dates_requested = []
    end

    def calculate_for_date(_benchmarks, date)
      @dates_requested << date
      @speedups[date]
    end
  end
end
