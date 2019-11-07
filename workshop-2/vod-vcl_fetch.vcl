  # Set 1s ttl if origin response HTTP status code is anything other than 200 and 206
  if (!http_status_matches(beresp.status, "200,206")) {
    set beresp.ttl = 1s;
  }

  # Enable Streaming Miss only for video or audio objects.
  # Below conditions checks for video or audio file extensions commonly used in
  # HTTP Streaming formats.
  if (req.url.ext ~ "m4s|mp4|ts|aac|fmp4") {
    set beresp.do_stream = true;
  }

  # Configure caching for VOD content
  if(req.url.path ~ "^/vod") {

    /* set stale_if_error and stale_while_revalidate (customize these values) */
    set beresp.stale_if_error = 7d;
    set beresp.stale_while_revalidate = 60s;

    # Cache VOD content for 1 year
    set beresp.ttl = 365d;
  }

