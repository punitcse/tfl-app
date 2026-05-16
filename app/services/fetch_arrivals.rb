# frozen_string_literal: true

class FetchArrivals
  def initialize(station_id:, mode: "tube")
    @station_id = station_id
    @mode      = mode
  end

  def call
    arrivals = TflClient.new.get("/StopPoint/#{@station_id}/Arrivals", mode: @mode)
    arrivals.map { |data| Arrival.from_api(data) }.sort_by(&:time_to_station)
  rescue TflClient::TflClientError => e
    Rails.logger.warn("[#{self.class.name}] #{@station_id}: #{e.message}")
    [] # Degrade gracefully, show No live arrivals instead of 500 error
  end
end
