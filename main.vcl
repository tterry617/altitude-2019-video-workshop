sub vcl_recv {
  if (req.http.Fastly-FF) {
    set req.max_stale_while_revalidate = 0s;
  }

#FASTLY recv

  if(req.url.path ~ "^/vod") {
    set req.backend = F_google;
    set req.url = regsub(req.url, "/vod", "/fastly-avalanche/videos");
    set req.http.Host = "storage.googleapis.com";
    set req.http.X-Service = "vod";
  }

  ############################################
  # VIDEO WORKSHOP: INSERT vcl_recv CODE HERE
  ############################################





  ############################################
  # END VIDEO WORKSHOP
  ############################################

  if (req.request != "HEAD" && req.request != "GET" && req.request != "FASTLYPURGE") {
    return(pass);
  }

  return(lookup);
}

sub vcl_fetch {
  /* handle 5XX (or any other unwanted status code) */
  if (beresp.status >= 500 && beresp.status < 600) {

    /* deliver stale if the object is available */
    if (stale.exists) {
      return(deliver_stale);
    }

    if (req.restarts < 1 && (req.request == "GET" || req.request == "HEAD")) {
      restart;
    }

    /* else go to vcl_error to deliver a synthetic */
    error 503;
  }

#FASTLY fetch

  if ((beresp.status == 500 || beresp.status == 503) && req.restarts < 1 && (req.request == "GET" || req.request == "HEAD")) {
    restart;
  }

  if (req.restarts > 0) {
    set beresp.http.Fastly-Restarts = req.restarts;
  }

  if (beresp.http.Set-Cookie) {
    set req.http.Fastly-Cachetype = "SETCOOKIE";
    return(pass);
  }

  if (beresp.http.Cache-Control ~ "private") {
    set req.http.Fastly-Cachetype = "PRIVATE";
    return(pass);
  }

  if (beresp.http.Expires || beresp.http.Surrogate-Control ~ "max-age" || beresp.http.Cache-Control ~ "(s-maxage|max-age)") {
    # keep the ttl here
  } else {
    # apply the default ttl
    set beresp.ttl = 3600s;
  }

  ############################################
  # VIDEO WORKSHOP: INSERT vcl_fetch CODE HERE
  ############################################









  ############################################
  # END VIDEO WORKSHOP
  ############################################

  return(deliver);
}

sub vcl_hit {
#FASTLY hit

  if (!obj.cacheable) {
    return(pass);
  }
  return(deliver);
}

sub vcl_miss {
#FASTLY miss

  ############################################
  # VIDEO WORKSHOP: INSERT vcl_miss CODE HERE
  ############################################







  ############################################
  # END VIDEO WORKSHOP
  ############################################
  return(fetch);
}

sub vcl_deliver {

#FASTLY deliver

  ############################################
  # VIDEO WORKSHOP: INSERT vcl_deliver CODE HERE
  ############################################







  ############################################
  # END VIDEO WORKSHOP
  ############################################


  return(deliver);
}

sub vcl_error {
#FASTLY error

  ############################################
  # VIDEO WORKSHOP: INSERT vcl_error CODE HERE
  ############################################


  ############################################
  # END VIDEO WORKSHOP
  ############################################

  /* handle 503s */
  if (obj.status >= 500 && obj.status < 600) {

    /* deliver stale object if it is available */
    if (stale.exists) {
      return(deliver_stale);
    }

    /* otherwise, return a synthetic */

    /* include your HTML response here */
    synthetic {"<!DOCTYPE html><html>Replace this text with the error page you would like to serve to clients if your origin is offline.</html>"};

    return(deliver);
  }

}

sub vcl_pass {
#FASTLY pass

  ############################################
  # VIDEO WORKSHOP: INSERT vcl_pass CODE HERE
  ############################################









  ############################################
  # END VIDEO WORKSHOP
  ############################################
}

sub vcl_log {

  ############################################
  # VIDEO WORKSHOP: INSERT vcl_log CODE HERE
  ############################################







  ############################################
  # END VIDEO WORKSHOP
  ############################################

#FASTLY log

}
