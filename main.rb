require './panel_stats.rb'

Dir["./data/**/*.csv"].each do |filename|
  opts = filename[/data\/8\//] ? { sample_rate: 10 } : {}
  panel_stats = PanelStats.new(filename, opts)
  panel_stats.write_results!
end