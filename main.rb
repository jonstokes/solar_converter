require 'csv'
require 'pry'
require 'yaml'

@panel_data = YAML.load_file('./data/panel_stats.yml')

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

def calculate_panel_efficiency(power_output, irradiance_value, panel_name)
  area = @panel_data[panel_name]["area"]
  irradiance_on_panel = irradiance_value * area

  ((power_output / irradiance_on_panel) * 100.00).round(2)
end

irradiance_column_header = "Irradiance(W/m2)"
normalized_irradiance_column_header = "Irradiance/100"
power_column_header = "Power(W)"
efficiency_column_header = "Efficiency(%)"
sun_score_column_header = "Sun Score"
power_score_column_header = "Power Score"
efficiency_score_column_header = "Efficiency Score"

Dir["./data/**/*.csv"].each do |filename|
  File.open(filename) do |multimeter_logs|
    multimeter_logs.gets
    table = CSV.new(multimeter_logs, headers: true).read
    irradiance = read_sms_irradiance_log(filename.sub(".csv", ".sms"))

    CSV.open(filename.sub("data", "output"), "w") do |collated_logs|
      panel_name = filename.split("/").last.split("-").first
      new_log_headers = irradiance ? table.headers + [irradiance_column_header, normalized_irradiance_column_header] : table.headers
      new_log_headers += [power_column_header, efficiency_column_header, power_score_column_header, sun_score_column_header, efficiency_score_column_header]
      collated_logs << new_log_headers
      table.each_with_index do |row, i|
        if irradiance
          next unless irrad_val = irradiance[i] && irradiance[i].last
          row[irradiance_column_header] = irrad_val
          row[normalized_irradiance_column_header] = (irrad_val.to_f / 100.0).round(3)
          row[power_column_header] = (row["Current(A)"].to_f * row["Voltage(V)"].to_f).round(2)
          row[efficiency_column_header] = calculate_panel_efficiency(
            row[power_column_header],
            irrad_val.to_f,
            panel_name
          )
          row[sun_score_column_header]  = (irrad_val.to_f / 10.0).round(1)
          row[power_score_column_header]  = ((row[power_column_header].to_f / 10.5) * 100.0).round(1)
          row[efficiency_score_column_header] = 
            ((row[sun_score_column_header] - row[power_score_column_header])).round(1)
        end
        row["Time"] = row["Time"].sub("0day", "")
        collated_logs << row
      end
    end  
  end
end

