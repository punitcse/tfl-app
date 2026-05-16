# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arrival do
  describe ".from_api" do
    let(:raw) do
      {
        "stationName"     => "Great Portland Street Underground Station",
        "lineId"          => "metropolitan",
        "lineName"        => "Metropolitan",
        "platformName"    => "Eastbound - Platform 1",
        "direction"       => "outbound",
        "destinationName" => "Aldgate Underground Station",
        "towards"         => "Aldgate",
        "timeToStation"   => 180,
        "currentLocation" => "Between Baker Street and Great Portland Street",
        "expectedArrival" => "2026-05-16T14:30:00Z"
      }
    end

    it "extracts main fields" do
      arrival = Arrival.from_api(raw)
      expect(arrival.line_name).to eq("Metropolitan")
      expect(arrival.destination).to eq("Aldgate")
      expect(arrival.time_to_station).to eq(180)
    end

    it "prefers `towards` over `destinationName`" do
      expect(Arrival.from_api(raw).destination).to eq("Aldgate")
    end

    it "falls back to destinationName when towards is missing" do
      a = Arrival.from_api(raw.merge("towards" => ""))
      expect(a.destination).to eq("Aldgate")
    end

    it "show expectedArrival into time" do
      expect(Arrival.from_api(raw).expected_arrival).to be_a(Time)
    end
  end

  describe "#direction" do
    it "uses the direction field when present" do
      a = Arrival.from_api("direction" => "inbound", "platformName" => "")
      expect(a.direction).to eq("inbound")
    end

    it "falls back to platform name for eastbound" do
      a = Arrival.from_api("direction" => "", "platformName" => "Eastbound - Platform 1")
      expect(a.direction).to eq("outbound")
    end

    it "falls back to platform name for westbound" do
      a = Arrival.from_api("direction" => "", "platformName" => "Westbound - Platform 2")
      expect(a.direction).to eq("inbound")
    end

    it "returns unknown when neither is informative" do
      a = Arrival.from_api("direction" => "", "platformName" => "")
      expect(a.direction).to eq("unknown")
    end
  end

  describe "#display_time" do
    it "returns 'Due' for times under 30 seconds" do
      a = Arrival.from_api("timeToStation" => 20)
      expect(a.display_time).to eq("Due")
    end

    it "rounds to nearest minute" do
      a = Arrival.from_api("timeToStation" => 150)
      expect(a.display_time).to eq("3 min")
    end
  end
end
