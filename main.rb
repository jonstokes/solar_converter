require './panel_stats.rb'

Dir["./data/**/*.csv"].each do |filename|
  panel_stats = PanelStats.new(filename)
  panel_stats.write_results!
end

