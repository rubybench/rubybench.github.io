require 'yaml'

module SiteHelpers
  def github_link(repository)
    link_to repository, "https://github.com/#{repository}"
  end

  def rss_entries
    @rss_entries ||= begin
      entries_file = File.expand_path('source/data/rss_entries.yml', app.root)
      File.exist?(entries_file) ? (YAML.safe_load_file(entries_file) || []) : []
    end
  end

  def rss_entry_title(entry)
    zjit = entry['zjit']
    change_pct = zjit['change_pct']
    direction = change_pct >= 0 ? 'up' : 'down'
    "This week in RubyBench: ZJIT performance #{direction} #{change_pct.abs}%"
  end

  def rss_entry_summary(entry)
    zjit = entry['zjit']
    week_date = Date.parse(entry['week_beginning'])
    change_pct = zjit['change_pct']
    trend = change_pct >= 0 ? 'improvement' : 'regression'

    html = []
    html << "<p>Week beginning: #{week_date.strftime('%e %b %Y')}</p>"
    html << "<h2>ZJIT</h2>"
    html << "<p>This week ZJIT saw an average performance #{trend} of #{change_pct.abs}% " \
            "across all benchmarks, when compared to the previous week. On average ZJIT is now " \
            "#{zjit['current_speedup']}x vs the interpreter, compared to " \
            "#{zjit['previous_speedup']}x last week.</p>"

    if zjit['improvements']&.any?
      html << "<p>The following benchmarks showed notable improvements:</p>"
      html << "<ul>"
      zjit['improvements'].each do |imp|
        html << "<li>#{imp['name']}: #{imp['current']}x (was #{imp['previous']}x)</li>"
      end
      html << "</ul>"
    end

    if zjit['regressions']&.any?
      html << "<p>Whilst these benchmarks regressed compared to last week:</p>"
      html << "<ul>"
      zjit['regressions'].each do |reg|
        html << "<li>#{reg['name']}: #{reg['current']}x (was #{reg['previous']}x)</li>"
      end
      html << "</ul>"
    end

    html << '<p>For more detailed results: <a href="https://rubybench.github.io/">View on RubyBench</a></p>'
    html.join("\n")
  end
end
