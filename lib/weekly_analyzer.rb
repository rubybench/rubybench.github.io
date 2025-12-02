class WeeklyAnalyzer
  IMPROVEMENT_THRESHOLD = 2.0
  REGRESSION_THRESHOLD = -1.0
  MAX_NOTABLE_CHANGES = 5

  Comparison = Struct.new(
    :current_average,
    :previous_average,
    :change_pct,
    :improvements,
    :regressions,
    keyword_init: true
  )

  Change = Struct.new(:name, :current, :previous, :change, keyword_init: true)

  def compare(current_speedups, previous_speedups)
    current_avg = average(current_speedups)
    previous_avg = average(previous_speedups)
    change_pct = percent_change(current_avg, previous_avg)

    Comparison.new(
      current_average: current_avg,
      previous_average: previous_avg,
      change_pct: change_pct,
      improvements: find_improvements(current_speedups, previous_speedups),
      regressions: find_regressions(current_speedups, previous_speedups)
    )
  end

  private

  def average(speedups)
    return 0.0 if speedups.empty?
    speedups.values.sum / speedups.size
  end

  def percent_change(current, previous)
    return 0.0 if previous.zero?
    ((current - previous) / previous * 100).round(1)
  end

  def find_improvements(current, previous)
    find_changes(current, previous) { |c| c > IMPROVEMENT_THRESHOLD }
      .sort_by { |c| -c.change }
      .first(MAX_NOTABLE_CHANGES)
  end

  def find_regressions(current, previous)
    find_changes(current, previous) { |c| c < REGRESSION_THRESHOLD }
      .sort_by { |c| -c.change }
      .first(MAX_NOTABLE_CHANGES)
  end

  def find_changes(current, previous)
    current.filter_map do |name, current_val|
      previous_val = previous[name]
      next unless previous_val
      change = percent_change(current_val, previous_val)
      next unless yield(change)
      Change.new(
        name: name,
        current: current_val.round(2),
        previous: previous_val.round(2),
        change: change.abs
      )
    end
  end
end
