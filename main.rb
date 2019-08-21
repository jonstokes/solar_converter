require 'csv'
require 'pry'

# Batch 1, offset 0

csv_list = Dir["./data/**/*.csv"]

csv_list.each do |filename|
  table = CSV.parse(filename, headers: true)
  binding.pry
end