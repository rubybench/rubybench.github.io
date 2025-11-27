require_relative 'test_helper'
require 'weekly_analyzer'

class WeeklyAnalyzerTest < Minitest::Test
  def setup
    @analyzer = WeeklyAnalyzer.new
  end

  def test_compare_calculates_averages
    current = {'a' => 2.0, 'b' => 4.0}
    previous = {'a' => 1.0, 'b' => 3.0}

    result = @analyzer.compare(current, previous)

    assert_equal 3.0, result.current_average
    assert_equal 2.0, result.previous_average
  end

  def test_compare_calculates_percent_change
    current = {'a' => 2.0}
    previous = {'a' => 1.0}

    result = @analyzer.compare(current, previous)

    assert_equal 100.0, result.change_pct
  end

  def test_compare_handles_negative_percent_change
    current = {'a' => 1.0}
    previous = {'a' => 2.0}

    result = @analyzer.compare(current, previous)

    assert_equal(-50.0, result.change_pct)
  end

  def test_compare_handles_zero_previous_average
    current = {'a' => 1.0}
    previous = {}

    result = @analyzer.compare(current, previous)

    assert_equal 0.0, result.change_pct
  end

  def test_improvements_filtered_by_threshold
    current = {'improved' => 1.5, 'not_improved' => 1.01}
    previous = {'improved' => 1.0, 'not_improved' => 1.0}

    result = @analyzer.compare(current, previous)

    assert_equal 1, result.improvements.size
    assert_equal 'improved', result.improvements.first.name
  end

  def test_regressions_filtered_by_threshold
    current = {'regressed' => 0.9, 'not_regressed' => 0.995}
    previous = {'regressed' => 1.0, 'not_regressed' => 1.0}

    result = @analyzer.compare(current, previous)

    assert_equal 1, result.regressions.size
    assert_equal 'regressed', result.regressions.first.name
  end

  def test_improvements_sorted_by_magnitude
    current = {'small' => 1.1, 'large' => 2.0}
    previous = {'small' => 1.0, 'large' => 1.0}

    result = @analyzer.compare(current, previous)

    assert_equal 'large', result.improvements.first.name
  end

  def test_improvements_limited_to_five
    current = (1..10).to_h { |i| ["bench#{i}", 2.0] }
    previous = (1..10).to_h { |i| ["bench#{i}", 1.0] }

    result = @analyzer.compare(current, previous)

    assert_equal 5, result.improvements.size
  end

  def test_regressions_limited_to_five
    current = (1..10).to_h { |i| ["bench#{i}", 0.5] }
    previous = (1..10).to_h { |i| ["bench#{i}", 1.0] }

    result = @analyzer.compare(current, previous)

    assert_equal 5, result.regressions.size
  end

  def test_changes_only_include_benchmarks_present_in_both_weeks
    current = {'new' => 2.0, 'existing' => 2.0}
    previous = {'existing' => 1.0, 'removed' => 1.0}

    result = @analyzer.compare(current, previous)

    names = result.improvements.map(&:name)
    assert_includes names, 'existing'
    refute_includes names, 'new'
    refute_includes names, 'removed'
  end

  def test_change_struct_contains_expected_fields
    current = {'bench' => 2.0}
    previous = {'bench' => 1.0}

    result = @analyzer.compare(current, previous)
    change = result.improvements.first

    assert_equal 'bench', change.name
    assert_equal 2.0, change.current
    assert_equal 1.0, change.previous
    assert_equal 100.0, change.change
  end
end
