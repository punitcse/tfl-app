# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /", type: :request do
  before { Rails.cache.clear }

  it "renders the station name and arrivals grouped by line" do
    stub_request(:get, %r{api\.tfl\.gov\.uk/StopPoint/Search/}).to_return(
      status: 200,
      body: { matches: [ { "id" => "940GZZLUGPS", "name" => "Great Portland Street Underground Station", "modes" => [ "tube" ] } ] }.to_json
    )

    stub_request(:get, %r{api\.tfl\.gov\.uk/StopPoint/940GZZLUGPS/Arrivals}).to_return(
      status: 200,
      body: [
        { "lineName" => "Metropolitan", "towards" => "Aldgate", "platformName" => "Eastbound - Platform 1",
          "direction" => "outbound", "timeToStation" => 120, "expectedArrival" => "2026-05-16T14:30:00Z" }
      ].to_json
    )

    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Great Portland Street")
    expect(response.body).to include("Metropolitan")
    expect(response.body).to include("Aldgate")
    expect(response.body).to include("2 min")
  end

  it "renders gracefully when TfL is down" do
    stub_request(:get, %r{api\.tfl\.gov\.uk/StopPoint/Search/}).to_return(status: 500)

    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Great Portland Street")
  end
end
