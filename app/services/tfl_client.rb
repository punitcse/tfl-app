# frozen_string_literal: true

require "net/http"

class TflClient
  BASE_URL = "https://api.tfl.gov.uk".freeze
  OPEN_TIMEOUT = 2 # Handshake should be tiny. Either succeeds in <500ms or the server is unreachable.
  READ_TIMEOUT = 5 # Arrival JSON is small (15-30KB), 5s response time should be more than enough.

  TflClientError = Class.new(StandardError)

  def get(path, params = {})
    uri = URI.join(BASE_URL, path)
    uri.query = URI.encode_www_form(params.compact)

    response = Net::HTTP.start(uri.host, uri.port,
                               use_ssl: true,
                               open_timeout: OPEN_TIMEOUT,
                               read_timeout: READ_TIMEOUT) do |http|
      http.get(uri.request_uri, "Accept" => "application/json")
    end

    raise TflClientError, "TfL #{response.code}: #{response.message}" unless response.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body)
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, JSON::ParserError => e
    raise TflClientError, "TfL request failed: #{e.class}: #{e.message}"
  end
end
