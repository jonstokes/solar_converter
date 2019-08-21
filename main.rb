require 'csv'
require 'pry'

# Common functions
def read_sms_irradiance_log(filename)
  begin
    File.read(filename).split("\n").map do |line|
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
  File.open(filename) do |f|
    f.gets
    csv = CSV.new(f, headers: true)
    irradiance = read_sms_irradiance_log(filename.sub(".csv", ".sms"))
    puts irradiance.inspect if irradiance
  end
end

