# frozen_string_literal: true

Arrival = Struct.new(
  :station_name, :line_name,
  :platform_name, :destination,
  :time_to_station, :expected_arrival,
  keyword_init: true
) do
  def self.from_api(raw)
    new(
      station_name:     raw["stationName"],
      line_name:        raw["lineName"],
      platform_name:    raw["platformName"].to_s,
      destination:      normalise_destination(raw),
      time_to_station:  raw["timeToStation"].to_i,
      expected_arrival: raw["expectedArrival"] && Time.parse(raw["expectedArrival"])
    )
  end

  def display_time
    return "Due" if time_to_station < 30
    "#{(time_to_station / 60.0).round} min"
  end

  def self.normalise_destination(raw)
    raw["towards"].presence ||
      raw["destinationName"].to_s.sub(/ Underground Station\z/, "")
  end
  private_class_method :normalise_destination
end
