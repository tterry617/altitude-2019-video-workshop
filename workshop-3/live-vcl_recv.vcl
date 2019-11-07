  if(req.url.path ~ "^/live") {
    set req.backend = F_live;
    set req.url = regsub(req.url, "/live", "/hls");
    set req.http.X-Service = "live";
  }