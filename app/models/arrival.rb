# frozen_string_literal: true

Arrival = Struct.new(
  :station_name, :line_id, :line_name,
  :platform_name, :direction, :destination,
  :current_location, :time_to_station, :expected_arrival,
  keyword_init: true
) do
  def self.from_api(raw)
    new(
      station_name:     raw["stationName"],
      line_id:          raw["lineId"],
      line_name:        raw["lineName"],
      platform_name:    raw["platformName"].to_s,
      direction:        normalise_direction(raw),
      destination:      normalise_destination(raw),
      current_location: raw["currentLocation"],
      time_to_station:  raw["timeToStation"].to_i,
      expected_arrival: raw["expectedArrival"] && Time.parse(raw["expectedArrival"])
    )
  end

  def display_time
    return "Due" if time_to_station < 30
    "#{(time_to_station / 60.0).round} min"
  end

  def platform_label
    platform_name[/Platform \d+/i] || platform_name
  end

  def self.normalise_direction(raw)
    d = raw["direction"].to_s
    return d if d.present?
    case raw["platformName"].to_s.downcase
    when /eastbound|southbound/ then "outbound"
    when /westbound|northbound/ then "inbound"
    else "unknown"
    end
  end
  private_class_method :normalise_direction

  def self.normalise_destination(raw)
    raw["towards"].presence ||
      raw["destinationName"].to_s.sub(/ Underground Station\z/, "")
  end
  private_class_method :normalise_destination
end
