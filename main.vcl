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
    #### vcl_error ####

  # req.backend.is_origin is not available in vcl_error
  if (!req.backend.is_shield) {
    set obj.http.log-origin:shield = server.datacenter;
  }
  ###################
  
Skip to content
Pull requests
Issues
Marketplace
Explore
@tterry617
Learn Git and GitHub without any code!

Using the Hello World guide, you’ll start a branch, write comments, and open a pull request.

1
3

    3

jamesfhall/altitude-2019-video-workshop
Code
Issues 0
Pull requests 0
Projects 0
Wiki
Security
Insights
altitude-2019-video-workshop/workshop-1/vcl_fetch.vcl
@jamesfhall jamesfhall Initial 2019 commit de3c305 5 days ago
20 lines (16 sloc) 774 Bytes
  #### vcl_fetch ####

  set beresp.http.log-timing:fetch = time.elapsed.usec;
  set beresp.http.log-timing:misspass = req.http.log-timing:misspass;
  set beresp.http.log-timing:do_stream = beresp.do_stream;

  set beresp.http.log-origin:ip = beresp.backend.ip;
  set beresp.http.log-origin:port = beresp.backend.port;
  set beresp.http.log-origin:name = regsub(beresp.backend.name, "^.+--", "");
  set beresp.http.log-origin:status = beresp.status;
  set beresp.http.log-origin:reason = beresp.response;

  set beresp.http.log-origin:method = bereq.method;
  set beresp.http.log-origin:url = bereq.url;
  set beresp.http.log-origin:host = bereq.http.host;

  if (req.backend.is_origin) {
    set beresp.http.log-origin:shield = server.datacenter;
  }
  ####################

  #### vcl_log ####
  
  set req.http.log-timing:log = time.elapsed.usec;

  declare local var.origin_ttfb FLOAT;
  declare local var.origin_ttlb FLOAT;

  if (fastly_info.state ~ "^(MISS|PASS)") {
    # origin_ttfb = fetch - misspass
    set var.origin_ttfb = std.atof(req.http.log-timing:fetch);
    set var.origin_ttfb -= std.atof(req.http.log-timing:misspass);

    if (req.http.log-timing:do_stream == "1") {
      # origin_ttlb = log - misspass
      # (and some clustering)
      set var.origin_ttlb = std.atof(req.http.log-timing:log);
      set var.origin_ttlb -= std.atof(req.http.log-timing:misspass);
    } else {
      # origin_ttlb = deliver - misspass
      # (and some clustering)
      set var.origin_ttlb = std.atof(req.http.log-timing:deliver);
      set var.origin_ttlb -= std.atof(req.http.log-timing:misspass);
    }
  }

  set var.origin_ttfb /= 1000;
  set var.origin_ttlb /= 1000;

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

  #### vcl_miss ####

  set req.http.log-timing:misspass = time.elapsed.usec;
  if (req.backend.is_origin) {
    unset bereq.http.log-request;
  }
  ##################
    #### vcl_pass ####

  set req.http.log-timing:misspass = time.elapsed.usec;
  if (req.backend.is_origin) {
    unset bereq.http.log-request;
  }
  ##################
  #### vcl_recv ####
 
  set client.geo.ip_override = req.http.fastly-client-ip;
  set req.http.log-request:host = req.http.host;
  set req.http.log-request:method = req.method;
  set req.http.log-request:url = req.url;

  # Grab the GUID
  if (req.url.path ~ "^/([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})") {
    set req.http.X-Fastly-GUID = re.group.1;
    set req.url = regsub(req.url,"^/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}","");
  } else {
    set req.http.X-Fastly-GUID = "";
  }
  ##################


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
 #### vcl_recv ####
 
  set client.geo.ip_override = req.http.fastly-client-ip;
  set req.http.log-request:host = req.http.host;
  set req.http.log-request:method = req.method;
  set req.http.log-request:url = req.url;

  # Grab the GUID
  if (req.url.path ~ "^/([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})") {
    set req.http.X-Fastly-GUID = re.group.1;
    set req.url = regsub(req.url,"^/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}","");
  } else {
    set req.http.X-Fastly-GUID = "";
  }
  ##################
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

  #### vcl_miss ####

  set req.http.log-timing:misspass = time.elapsed.usec;
  if (req.backend.is_origin) {
    unset bereq.http.log-request;
  }
  ##################





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
