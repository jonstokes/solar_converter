require 'csv'
require 'pry'

# Common functions
def read_sms_irradiance_log(filename)
  begin
    irradiance_log = File.read(filename).split("\n")
    irradiance_log.shift
    irradiance_log.map do |line|
      line.split(/\s/).select do |value|
        value.length > 0
      end
    end
  rescue
    nil
  end
end

# Batch 1, offset 0

csv_list = Dir["./data/**/*.csv"]

csv_list.each do |filename|
  File.open(filename) do |multimeter_logs|
    multimeter_logs.gets
    table = CSV.new(multimeter_logs, headers: true).read
    if irradiance = read_sms_irradiance_log(filename.sub(".csv", ".sms"))
      CSV.open(filename.sub("data", "output"), "w") do |collated_logs|
        collated_logs << table.headers  + ["Irradiance"]
        table.each_with_index do |row, i|
          next unless row["Irradiance"] = irradiance[i] && irradiance[i].last
          collated_logs << row
        end
      end      
    end
  end
end

