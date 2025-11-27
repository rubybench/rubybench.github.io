require_relative 'benchmark_fetcher'
require_relative 'benchmark_registry'
require_relative 'speedup_calculator'
require_relative 'weekly_analyzer'

class RSSGenerator
  def self.default
    new(
      registry: BenchmarkRegistry.new,
      calculator: SpeedupCalculator.new(fetcher: BenchmarkFetcher.new),
      analyzer: WeeklyAnalyzer.new
    )
  end

  def initialize(registry:, calculator:, analyzer:)
    @registry = registry
    @calculator = calculator
    @analyzer = analyzer
  end

  def generate_entry(week_beginning_date)
    benchmarks = @registry.names
    return nil if benchmarks.empty?

    previous_week = week_beginning_date - 7
    current = @calculator.calculate_for_date(benchmarks, week_beginning_date)
    previous = @calculator.calculate_for_date(benchmarks, previous_week)
    return nil if current.nil? || previous.nil?

    comparison = @analyzer.compare(current, previous)
    build_entry(week_beginning_date, comparison)
  end

  private

  def build_entry(week_beginning_date, comparison)
    {
      'week_beginning' => week_beginning_date.strftime('%Y-%m-%d'),
      'guid' => "rubybench-week-#{week_beginning_date.strftime('%Y-%m-%d')}",
      'link' => 'https://rubybench.github.io/',
      'zjit' => {
        'current_speedup' => comparison.current_average.round(2),
        'previous_speedup' => comparison.previous_average.round(2),
        'change_pct' => comparison.change_pct,
        'improvements' => comparison.improvements.map { |i|
          {'name' => i.name, 'current' => i.current, 'previous' => i.previous, 'change' => i.change}
        },
        'regressions' => comparison.regressions.map { |r|
          {'name' => r.name, 'current' => r.current, 'previous' => r.previous, 'change' => r.change}
        }
      }
    }
  end
end
