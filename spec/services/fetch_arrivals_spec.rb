# frozen_string_literal: true

require "rails_helper"

RSpec.describe FetchArrivals do
  subject(:service) { described_class.new(station_id: "940GZZLUGPS") }

  let(:arrivals_url) { %r{\A#{Regexp.escape(TflClient::BASE_URL)}/StopPoint/940GZZLUGPS/Arrivals} }

  describe "#call" do
    context "when the API responds successfully" do
      before do
        stub_request(:get, arrivals_url).to_return(
          status: 200,
          body: [
            { "timeToStation" => 300, "lineName" => "Metropolitan", "platformName" => "" },
            { "timeToStation" => 60,  "lineName" => "Circle",       "platformName" => "" }
          ].to_json
        )
      end

      it "returns Arrival objects" do
        expect(service.call).to all(be_a(Arrival))
      end

      it "sorts by time to station ascending" do
        expect(service.call.map(&:time_to_station)).to eq([ 60, 300 ])
      end
    end

    context "when the API returns an error" do
      before do
        stub_request(:get, arrivals_url).to_return(status: 500)
      end

      it "returns an empty array" do
        expect(service.call).to eq([])
      end
    end
  end
end
