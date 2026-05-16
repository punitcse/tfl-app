# frozen_string_literal: true

class SearchStation
  # Station IDs are extremely stable. Cache for a day as a balance between
  # avoiding unnecessary API calls and from any unexpected changes.
  CACHE_TTL = 24.hours

  NotFound = Class.new(StandardError)

  def initialize(name:)
    @name = name
  end

  def call
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      raw = TflClient.new.get("/StopPoint/Search/#{ERB::Util.url_encode(@name)}", modes: "tube")

      match = pick_match(Array(raw["matches"]))
      raise NotFound, "No tube station matching #{@name.inspect}" unless match
      match["id"]
    end
  rescue TflClient::TflClientError => e
    Rails.logger.warn("[#{self.class.name} #{@name}: #{e.message}")
    raise NotFound, "TfL search failed for #{@name.inspect}"
  end

  private

  def pick_match(matches)
    matches.find { |m| m["name"] == "#{@name} Underground Station" } ||
      matches.find { |m| Array(m["modes"]).include?("tube") }
  end

  def cache_key
    "station-search-#{@name.downcase.gsub(/\s+/, '-')}"
  end
end
