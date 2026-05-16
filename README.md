# Great Portland Street — Live Tube Arrivals

A small Rails app that displays the next trains due at "Great Portland Street underground station", using the [Transport for London Unified API](https://api.tfl.gov.uk/).

![Screenshot of the arrivals page](docs/screenshot.png)

---

## What it does

- Resolves the station name "Great Portland Street" to a station ID via the TfL [StopPoint Search API](https://api-portal.tfl.gov.uk/api-details#api=StopPoint&operation=StopPoint_SearchByQueryQueryQueryModesQueryFaresOnlyQueryMaxResultsQueryLine)
- Fetches live arrival predictions for that station via the TfL [StopPoint Arrivals API](https://api-portal.tfl.gov.uk/api-details#api=StopPoint&operation=StopPoint_ArrivalsByPathId).
- Renders arrivals grouped by line, split inbound/outbound, sorted by time to arrival, with platform information for each train.

---

## Running it locally

### Requirements

- Ruby `3.3.11`
- Rails `7.2.3`
- Bundler `2.5.3`

A `.ruby-version` file is included for [rbenv](https://github.com/rbenv/rbenv).

```bash
git clone https://github.com/punitcse/tfl-app.git
cd tfl-app
bundle install
bin/dev
```

Alternatively, run the two processes manually in separate terminals:

```bash
bin/rails server -p 3000
bin/rails tailwindcss:watch
```

Open <http://localhost:3000> in your browser.

### Running the tests

```bash
bundle exec rspec
```

All HTTP calls are stubbed via WebMock — the test suite does not hit the live TfL API.

---

## How it works

The app resolves the station name "Great Portland Street" to a station ID via TfL's StopPoint Search API, then fetches live arrivals for that ID. Arrivals are grouped by line, split inbound/outbound, sorted by time to arrival.

The interesting code lives in three places:

- `SearchStation` performs the name → stations ids lookup. Cached for 24 hours since station IDs don't change.
- `FetchArrivals` fetches the live data. Not cached, arrivals are live data and even 20 seconds of staleness is meaningful.
- `Arrival` is a Struct that wraps a single TfL prediction, with display helpers and normalises the raw response.

## Design notes

**Caching is asymmetric on purpose.** Station IDs are permanent, so cache them long. Arrivals are live, so don't cache them. For a multi-user production deployment I'd add a short (~5s) arrivals cache to coalesce concurrent requests under TfL's rate limit, but at test-app scale it's not worth the staleness.

**Net::HTTP rather than Faraday.** Two endpoints don't justify a gem. Retry middleware doesn't really help inside a synchronous request anyway — if TfL is degraded, retrying just makes the user wait longer for the same empty state. Tight timeouts (2s open, 5s read) protect the request thread; on failure the view degrades to an empty state rather than 500-ing.

**Search matching.** TfL's search returns multiple results for a query. `SearchStation` looks for an exact name match first, then falls back to the first tube-mode result. Tested explicitly.

**`Arrival` is a Struct, not ActiveRecord.** Arrivals are transient nothing to persist. The Struct normalises TfL's messy response (sometimes `direction` is empty, sometimes `towards` is missing) once at the boundary, so the rest of the app works with consistent objects.

## What's not built

- **Auto-refresh.** Scoped out for time. The `_arrivals` partial is already extracted; a Turbo Frame with a polling Stimulus controller would wire in without restructuring.
- **Last-known-good fallback.** During a TfL outage, the page goes empty. In production I'd cache the most recent successful response separately and serve it stale with a "last updated X ago" notice.

## API notes

A few quirks I hit while building:

- `direction` is sometimes empty (Circle line in particular). `Arrival#direction` falls back to parsing the platform name.
- `towards` is more readable than `destinationName` ("Aldgate" vs "Aldgate Underground Station"). Preferred when present.
- TfL's Search endpoint puts the query in the URL path. `ERB::Util.url_encode` produces `%20` for spaces; `CGI.escape` produces `+`, which TfL interprets literally.

No API key is required, though TfL rate-limits unauthenticated traffic to about 50 req/min. Register at the [TfL portal](https://api-portal.tfl.gov.uk/) and add the key to Rails credentials under `tfl.app_key` to lift the limit.
