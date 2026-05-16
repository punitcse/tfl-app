class ArrivalsController < ApplicationController
  STATION_NAME = "Great Portland Street".freeze

  def show
    station_id = SearchStation.new(name: STATION_NAME).call
    arrivals  = FetchArrivals.new(station_id:).call

    @station_name = STATION_NAME
    @grouped_arrivals = arrivals.group_by(&:platform_name)
  rescue SearchStation::NotFound => e
    @station_name = STATION_NAME
    @grouped_arrivals = {}
    flash.now[:alert] = "Couldn't load station info right now."
  end
end
