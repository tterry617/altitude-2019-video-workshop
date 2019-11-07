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