class SpeedupCalculator
  VM_INDEX = 0
  ZJIT_INDEX = 2

  def initialize(fetcher:)
    @fetcher = fetcher
  end

  def calculate_for_date(benchmark_names, target_date)
    speedups = {}
    benchmark_names.each do |name|
      data = @fetcher.fetch(name)
      next unless data
      speedup = speedup_at_date(data, target_date)
      speedups[name] = speedup if speedup
    end
    return nil if speedups.empty?
    speedups
  end

  private

  def speedup_at_date(benchmark_data, target_date)
    return nil unless benchmark_data.is_a?(Hash)

    dates = benchmark_data.keys.map { |k| k.to_i }.sort.reverse
    return nil if dates.empty?

    target_int = target_date.strftime('%Y%m%d').to_i
    date_key = dates.find { |d| d <= target_int } || dates.last
    return nil unless date_key

    entry = benchmark_data[date_key] || benchmark_data[date_key.to_s]
    return nil unless entry.is_a?(Array) && entry.length >= 3

    vm_result = entry[VM_INDEX]
    zjit_result = entry[ZJIT_INDEX]
    return nil unless vm_result && zjit_result && vm_result > 0 && zjit_result > 0

    vm_result.to_f / zjit_result.to_f
  end
end
