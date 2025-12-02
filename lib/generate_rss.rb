#!/usr/bin/env ruby

require_relative 'rss_generator'
require 'fileutils'
require 'date'
require 'yaml'

today = Date.today
week_beginning = today - (today.wday - 1) % 7

generator = RSSGenerator.default
entry = generator.generate_entry(week_beginning)

if entry.nil?
  puts "Failed to generate RSS entry for week beginning #{week_beginning}"
  exit 1
end

entries_file = File.expand_path('../source/data/rss_entries.yml', __dir__)
entries = YAML.safe_load_file(entries_file)

if existing_index = entries.index { |e| e['guid'] == entry['guid'] }
  entries[existing_index] = entry
else
  entries.unshift(entry)
end

entries = entries.first(20)
File.write(entries_file, entries.to_yaml)

puts "Generated RSS entry for week beginning #{entry['week_beginning']}"

