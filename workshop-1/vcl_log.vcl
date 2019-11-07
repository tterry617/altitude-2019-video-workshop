  #### vcl_log ####
  
  # ttfb = time.to_first_byte (just before deliver)
  declare local var.response_ttfb FLOAT;
  set var.response_ttfb = time.to_first_byte;
  set var.response_ttfb *= 1000;

  # ttlb = log
  declare local var.response_ttlb FLOAT;
  set var.response_ttlb = std.atof(req.http.log-timing:log);
  set var.response_ttlb /= 1000;

  declare local var.client_tcpi_rtt INTEGER;
  set var.client_tcpi_rtt = client.socket.tcpi_rtt;
  set var.client_tcpi_rtt /= 1000;

  # Only log origin/shield info if we actually went to origin/shield
  if (fastly_info.state !~ "^(MISS|PASS)") {
    unset req.http.log-origin:host;
    unset req.http.log-origin:ip;
    unset req.http.log-origin:method;
    unset req.http.log-origin:name;
    unset req.http.log-origin:port;
    unset req.http.log-origin:reason;
    unset req.http.log-origin:shield;
    unset req.http.log-origin:status;
    unset req.http.log-origin:url;
    set var.origin_ttfb = math.NAN;
    set var.origin_ttlb = math.NAN;
  }

  set req.http.log-client:tcpi_rtt = var.client_tcpi_rtt;
  set req.http.log-origin:ttfb = var.origin_ttfb;
  set req.http.log-origin:ttlb = var.origin_ttlb;
  set req.http.log-response:ttfb = var.response_ttfb;
  set req.http.log-response:ttlb = var.response_ttlb;
  #################