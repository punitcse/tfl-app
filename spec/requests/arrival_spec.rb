# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /", type: :request do
  let(:station_name) { ArrivalsController::STATION_NAME }
  let(:station_id)   { "940GZZLUGPS" }
  let(:search_url)   { %r{\A#{Regexp.escape(TflClient::BASE_URL)}/StopPoint/Search/#{ERB::Util.url_encode(station_name)}} }
  let(:arrivals_url) { %r{\A#{Regexp.escape(TflClient::BASE_URL)}/StopPoint/#{station_id}/Arrivals} }

  before { Rails.cache.clear }

  context "when TfL responds successfully" do
    before do
      stub_request(:get, search_url).to_return(
        status: 200,
        body: { matches: [ { "id" => station_id, "name" => "#{station_name} Underground Station", "modes" => [ "tube" ] } ] }.to_json
      )
      stub_request(:get, arrivals_url).to_return(
        status: 200,
        body: [ {
          "lineName" => "Metropolitan", "towards" => "Aldgate",
          "platformName" => "Eastbound - Platform 1", "direction" => "outbound",
          "timeToStation" => 120, "expectedArrival" => "2026-05-16T14:30:00Z"
        } ].to_json
      )
      get "/"
    end

    it "renders the station name and arrivals grouped by line" do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(station_name, "Metropolitan", "Aldgate", "2 min")
    end
  end

  context "when TfL is down" do
    before do
      stub_request(:get, search_url).to_return(status: 500)
      get "/"
    end

    it "renders the page without raising" do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(station_name)
    end
  end
end
