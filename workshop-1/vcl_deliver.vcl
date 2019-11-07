  #### vcl_deliver ####

  set req.http.log-timing:deliver = time.elapsed.usec;
  set req.http.log-timing:fetch = resp.http.log-timing:fetch;
  set req.http.log-timing:misspass = resp.http.log-timing:misspass;
  set req.http.log-timing:do_stream = resp.http.log-timing:do_stream;
  unset resp.http.log-timing;
  unset resp.http.X-Fastly-GUID;

  set req.http.log-origin = resp.http.log-origin;

  if (fastly.ff.visits_this_service == 0) {
    unset resp.http.log-origin;
  }
  #####################