  #### vcl_miss ####

  set req.http.log-timing:misspass = time.elapsed.usec;
  if (req.backend.is_origin) {
    unset bereq.http.log-request;
  }
  ##################