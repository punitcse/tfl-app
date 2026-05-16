# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchStation do
  subject(:service) { described_class.new(name: name) }

  let(:name)       { "Great Portland Street" }
  let(:search_url) { %r{\A#{Regexp.escape(TflClient::BASE_URL)}/StopPoint/Search/#{ERB::Util.url_encode(name)}} }
  let(:exact_match) do
    { "id" => "940GZZLUGPS", "name" => "Great Portland Street Underground Station", "modes" => [ "tube" ] }
  end

  before { Rails.cache.clear }

  describe "#call" do
    context "when the station name matches exactly" do
      before do
        stub_request(:get, search_url).to_return(status: 200, body: { matches: [ exact_match ] }.to_json)
      end

      it { expect(service.call).to eq("940GZZLUGPS") }
    end

    context "when there is no exact name match" do
      before do
        stub_request(:get, search_url).to_return(
          status: 200,
          body: { matches: [ { "id" => "ABC", "name" => "Something Else", "modes" => [ "tube" ] } ] }.to_json
        )
      end

      it "falls back to the first tube-mode match" do
        expect(service.call).to eq("ABC")
      end
    end

    context "when no matches are returned" do
      before do
        stub_request(:get, search_url).to_return(status: 200, body: { matches: [] }.to_json)
      end

      it { expect { service.call }.to raise_error(SearchStation::NotFound) }
    end

    context "when the API returns an error" do
      before do
        stub_request(:get, search_url).to_return(status: 500)
      end

      it { expect { service.call }.to raise_error(SearchStation::NotFound) }
    end

    context "when called multiple times" do
      before do
        allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      end

      it "only hits the API once" do
        stub = stub_request(:get, search_url).to_return(status: 200, body: { matches: [ exact_match ] }.to_json)
        2.times { service.call }
        expect(stub).to have_been_requested.once
      end
    end
  end
end
