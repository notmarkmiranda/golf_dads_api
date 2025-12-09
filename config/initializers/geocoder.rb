# Geocoder configuration
# https://github.com/alexreisner/geocoder
Geocoder.configure(
  # Geocoding service timeout (in seconds)
  timeout: 5,

  # Use Nominatim (OpenStreetMap) for free geocoding
  # No API key required, but rate limited to 1 request/second
  lookup: :nominatim,

  # Always use HTTPS
  use_https: true,

  # Cache results to avoid repeated lookups for same address
  cache: Rails.cache,
  cache_prefix: "geocoder:",

  # Units for distance calculations
  units: :mi,

  # Nominatim requires a User-Agent header
  http_headers: {
    "User-Agent" => "GolfDadsApp/1.0"
  }
)
