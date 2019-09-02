require 'csv'
require 'pry'
require 'yaml'

PANEL_DATA = YAML.load_file('./data/panel_stats.yml')

class PanelStats
  COLUMN_HEADERS = {
    irradiance: "Irradiance(W/m2)",
    normalized_irradiance: "Irradiance/100",
    power: "Power(W)",
    efficiency: "Efficiency(%)",
    sun_score: "Sun Score",
    power_score: "Power Score",
    efficiency_score: "Efficiency Score",
    current: "Current(A)",
    voltage: "Voltage(V)"
  }
  
  class Calculator
    attr_reader :row, :panel_name

    COLUMN_HEADERS.keys.each do |key|
      define_method key do
        row[COLUMN_HEADERS[key.to_sym]].to_f
      end
  
      define_method "set_#{key}" do |value|
        @row[COLUMN_HEADERS[key.to_sym]] = value
      end
    end
  
    def initialize(row:, panel_name:, irradiance:)
      @row = row
      @panel_name = panel_name
      @row[COLUMN_HEADERS[:irradiance]] = irradiance.to_f
    end
  
    def panel_data(key)
      PANEL_DATA[panel_name][key.to_s]
    end

    def panel_area
      panel_data(:area)
    end
  
    def pmax
      panel_data(:pmax)
    end

    def irradiance_on_panel
      irradiance * panel_area
    end

    def add_power_data!
      set_power (current * voltage).round(2)
      puts "Setting power score for #{panel_name} (#{power}/#{pmax})" if power > pmax
      set_power_score ((power / pmax) * 100.0).round(1)
      set_sun_score (irradiance / 10.0).round(1)
    end

    def add_irradiance_data!
      set_normalized_irradiance (irradiance / 100.0).round(3)
      set_efficiency ((power / irradiance_on_panel) * 100.00).round(2)
      #set_efficiency_score (sun_score - power_score).round(1)
    end
  end

  attr_reader :filename, :table, :irradiance_log, :multimeter_log

  def initialize(filename)
    puts "Reading #{filename}"
    @filename = filename
    @multimeter_log = File.open(filename, "r") do |file|
      file.gets
      file.read
    end
    @table = CSV.new(multimeter_log, headers: true).read
  end

  def new_log_headers
    new_headers = table.headers.dup + [COLUMN_HEADERS[:power], COLUMN_HEADERS[:power_score], COLUMN_HEADERS[:sun_score]]
    if irradiance_log
      new_headers += [COLUMN_HEADERS[:irradiance], COLUMN_HEADERS[:normalized_irradiance], COLUMN_HEADERS[:efficiency], COLUMN_HEADERS[:efficiency_score]]
    end
    new_headers
  end

  def irradiance_log
    @irradiance_log ||= begin
      irradiance_log = File.read(filename.sub(".csv", ".sms")).split("\n")
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

  def irradiance_value_at_index(i)
    return unless irradiance_log && irradiance_log[i]
    irradiance_log[i].last
  end

  def panel_name
    @panel_name ||= filename.split("/").last.split("-").first
  end

  def write_results!
    csv_filename = filename.sub("data", "output")
    table.each_with_index do |row, i|
      calculator = Calculator.new(
        row: row,
        panel_name: panel_name, 
        irradiance: irradiance_value_at_index(i) ||  "0.0"
      )
      calculator.add_power_data!

      if irradiance_log
        next unless irradiance_value_at_index(i)
        calculator.add_irradiance_data!
      end

      row["Time"] = row["Time"].sub("0day", "")
    end

    CSV.open(csv_filename, "w", write_headers: true, headers: table.headers) do |collated_logs|
      table.each { |row| collated_logs << row }
    end
  end
end
