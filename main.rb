require 'csv'
require 'pry'
require 'yaml'

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

irradiance_column_header = "Irradiance (W/m2)"
normalized_irradiance_column_header = "Irradiance/100"

panel_data = YAML.load_file('./data/panel_stats.yml')

Dir["./data/**/*.csv"].each do |filename|
  File.open(filename) do |multimeter_logs|
    multimeter_logs.gets
    table = CSV.new(multimeter_logs, headers: true).read
    irradiance = read_sms_irradiance_log(filename.sub(".csv", ".sms"))

    CSV.open(filename.sub("data", "output"), "w") do |collated_logs|
      new_log_headers = irradiance ? table.headers + [irradiance_column_header, normalized_irradiance_column_header] : table.headers
      collated_logs << new_log_headers
      table.each_with_index do |row, i|
        if irradiance
          next unless irradiance[i]
          row[irradiance_column_header] = irradiance[i].last
          row[normalized_irradiance_column_header] = irradiance[i].last.to_f / 100.0
        end
        row["Time"] = row["Time"].sub("0day", "")
        collated_logs << row
      end
    end  
  end
end

