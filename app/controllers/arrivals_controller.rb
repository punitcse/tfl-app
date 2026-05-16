class ArrivalsController < ApplicationController
  STATION_NAME = "Great Portland Street".freeze

  def show
    station_id = SearchStation.new(name: STATION_NAME).call
    arrivals  = FetchArrivals.new(station_id:).call

    @station_name = STATION_NAME
    @grouped = arrivals.group_by(&:line_name)
                       .transform_values { |list| list.group_by(&:direction) }
  rescue SearchStation::NotFound => e
    @station_name = STATION_NAME
    @grouped = {}
    flash.now[:alert] = "Couldn't load station info right now."
  end
end
