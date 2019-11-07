  if(req.http.X-service == "live") {
    # Set 1s ttls for video manifest and 3600s ttls for segments of HTTP Streaming formats.
    # Microsoft Smooth Streaming format manifest and segments do not have file extensions.
    # Look for the keywords "Manifest" and "QualityLevel" to identify manifest and segment requests.
    if (req.url.ext ~ "m3u8|mpd" || req.url.path ~ "Manifest") {
      set beresp.ttl = 1s;
    } else {
      if (req.url.ext ~ "m4s|mp4|ts|aac|fmp4" || req.url.path ~ "QualityLevel") {
        set beresp.ttl = 1h;
      }
    }
  }