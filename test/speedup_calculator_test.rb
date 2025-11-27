require_relative 'test_helper'
require 'speedup_calculator'

class SpeedupCalculatorTest < Minitest::Test
  def setup
    @fetcher = MockFetcher.new
    @calculator = SpeedupCalculator.new(fetcher: @fetcher)
  end

  def test_calculate_for_date_returns_speedups_hash
    @fetcher.data['bench1'] = {20251124 => [100.0, 50.0, 50.0]}

    result = @calculator.calculate_for_date(['bench1'], Date.new(2025, 11, 24))

    assert_equal({'bench1' => 2.0}, result)
  end

  def test_returns_nil_when_no_benchmarks_have_data
    @fetcher.data['bench1'] = nil

    result = @calculator.calculate_for_date(['bench1'], Date.new(2025, 11, 24))

    assert_nil result
  end

  def test_skips_benchmarks_with_no_data
    @fetcher.data['good'] = {20251124 => [100.0, 50.0, 50.0]}
    @fetcher.data['bad'] = nil

    result = @calculator.calculate_for_date(['good', 'bad'], Date.new(2025, 11, 24))

    assert_equal({'good' => 2.0}, result)
  end

  def test_uses_most_recent_date_at_or_before_target
    @fetcher.data['bench'] = {
      20251120 => [100.0, 50.0, 50.0],
      20251125 => [200.0, 50.0, 100.0]
    }

    result = @calculator.calculate_for_date(['bench'], Date.new(2025, 11, 24))

    assert_equal 2.0, result['bench']
  end

  def test_falls_back_to_oldest_date_if_all_dates_are_future
    @fetcher.data['bench'] = {20251130 => [100.0, 50.0, 50.0]}

    result = @calculator.calculate_for_date(['bench'], Date.new(2025, 11, 24))

    assert_equal 2.0, result['bench']
  end

  def test_calculates_speedup_as_vm_divided_by_zjit
    @fetcher.data['bench'] = {20251124 => [200.0, 100.0, 50.0]}

    result = @calculator.calculate_for_date(['bench'], Date.new(2025, 11, 24))

    assert_equal 4.0, result['bench']
  end

  def test_handles_string_date_keys
    @fetcher.data['bench'] = {'20251124' => [100.0, 50.0, 50.0]}

    result = @calculator.calculate_for_date(['bench'], Date.new(2025, 11, 24))

    assert_equal 2.0, result['bench']
  end

  def test_skips_entry_with_zero_vm_result
    @fetcher.data['bench'] = {20251124 => [0.0, 50.0, 50.0]}

    result = @calculator.calculate_for_date(['bench'], Date.new(2025, 11, 24))

    assert_nil result
  end

  def test_skips_entry_with_zero_zjit_result
    @fetcher.data['bench'] = {20251124 => [100.0, 50.0, 0.0]}

    result = @calculator.calculate_for_date(['bench'], Date.new(2025, 11, 24))

    assert_nil result
  end

  def test_skips_entry_with_insufficient_array_length
    @fetcher.data['bench'] = {20251124 => [100.0, 50.0]}

    result = @calculator.calculate_for_date(['bench'], Date.new(2025, 11, 24))

    assert_nil result
  end

  class MockFetcher
    attr_accessor :data

    def initialize
      @data = {}
    end

    def fetch(name)
      @data[name]
    end
  end
end
