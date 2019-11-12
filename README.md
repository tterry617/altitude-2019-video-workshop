# Fastly Altitude 2019 Video Delivery Workshop

Below you will find resources required for the workshop on Video Delivery at Fastly's Altitude 2019 in New York.

Clone this repo and refer to the sheet given to you at the workshop which contains your specific Fastly Service ID, and the domain attached to your specific service.

## Suggested Reading

Fastly documentation:

* [API documentation](https://docs.fastly.com/api/)
* [Working with services](https://docs.fastly.com/api/config#service)
* [Working with service versions](https://docs.fastly.com/api/config#version)
* [Fastly Streaming Logs](https://docs.fastly.com/guides/streaming-logs/setting-up-remote-log-streaming)
* [Useful variables to log](https://docs.fastly.com/guides/streaming-logs/useful-variables-to-log)
* [Configuration guidelines for video streaming](https://docs.fastly.com/guides/live-streaming/configuration-guidelines-for-live-streaming)

## Table of Contents

* [Initial Setup](#setup)
* [General Tips](#tips)
* [Workshop 1: Visibility and Real Time Log Streaming](#workshop1)
* [Workshop 2: VOD Optimizations](#workshop2)
* [Workshop 3: Live Optimizations](#workshop3)

<a id="setup"></a>
## Initial Setup

In order to ease usage of the API, let's set a few environment variables for our API key and your personal service ID.

````
API Key: xZ8F-XZdRWiOBnu7Cy4QuVn5cEECSPOP
````

Grab the API key from the readme above, and your service ID from the sheet given to you at the beginning of this workshop (this is assuming a Bash shell):

````
export API_KEY=<api_key>
export SERVICE_ID=<service_id>
````

<a id="tips"></a>
## General Tips

We will be working with an API that returns JSON as its response.

**Make sure you are taking note of the responses!**

We will be working with data from these API responses to complete the different parts of the workshop.

In order to read the JSON in a human friendly way, it is suggested you install some sort of JSON parser.

[JQ](https://stedolan.github.io/jq/) can be used for this purpose. A tutorial for basic usage can be found [here](https://stedolan.github.io/jq/tutorial/).

**If at any time you get version drift in this workshop, you can find out your current active version and work from that using the following command:**

`curl -H "Fastly-Key: ${API_KEY}" https://api.fastly.com/service/${SERVICE_ID}/details | jq`

You will receive a JSON response listing all versions. You will want to find the one where `"active": true`:

```
{
  "testing": false,
  "locked": true,
  "number": 10,
  "active": true,
  "service_id": "1OPpKYvOlWVx37twfGVsq0",
  "staging": false,
  "created_at": "2017-06-16T01:07:30+00:00",
  "deleted_at": null,
  "comment": "",
  "updated_at": "2017-06-16T01:14:14+00:00",
  "deployed": false
},
```

You can then clone from your current active version and work from there.

<a id="workshop1"></a>
## Workshop 1: Visibility and Real Time Log Streaming

### Step 1: Clone service

Below is a curl command to use the Fastly API to clone a version of your service to one we can edit. Use the following command to clone our service from the current active (1) to a new development version (2)

````
curl -H "Fastly-Key: ${API_KEY}" -X PUT https://api.fastly.com/service/${SERVICE_ID}/version/1/clone | jq
````

You should see a response like this:

````
{
  "testing": false,
  "locked": false,
  "number": 2,
  "active": false,
  "service_id": "2KVPqlEPCh6tRCVQBxlUYk",
  "staging": false,
  "created_at": "2018-08-31T17:04:51Z",
  "deleted_at": null,
  "comment": "",
  "updated_at": "2018-08-31T17:16:00Z",
  "deployed": false
}
````

### Step 2: Configure logging endpoint

In this repo you will find a file `log_format.txt`. This is a list of variables we will ne sending to our logging endpoint. We will be url encoding these and uploading them to the Fastly logging API.

We are working with Sumo Logic for this workshop, you can use any logging endpoint we support to suit your needs.

In the directory of your git repo, run the following command to configure your real time logs:

````
curl -X POST https://api.fastly.com/service/${SERVICE_ID}/version/2/logging/sumologic -H "Fastly-Key: ${API_KEY}" -d@log_format.txt | jq
````

Sample response:

````
{
  "name": "workshop1-SumoLogic",
  "message_type": "blank",
  "format": "<redacted>",
  "url": "https://endpoint3.collection.us2.sumologic.com/receiver/v1/http/ZaVnC4dhaV1z1AeZ1Y1MjfCQd5Ypwxi7jXvw0uY2hR3ycKg_lCVd77rj5lgKm-8krz30nPgv-dBhWCqIl_et_Yez_BMeVUnv2S4d9iqYD1uWMqOZcgiT-A==",
  "service_id": "2KVPqlEPCh6tRCVQBxlUYk",
  "version": "1",
  "placement": null,
  "format_version": "2",
  "response_condition": "",
  "updated_at": "2018-09-08T09:12:09Z",
  "deleted_at": null,
  "created_at": "2018-09-08T09:12:09Z"
}
````

### Step 3: Adding our custom logging variables to VCL

We will now add custom variable names in our configuration to be sent to our previously configured endpoint.

In this repo there is included a `main.vcl` file which is our base config. In each section where we will be adding code, you will see a block similar to this:

````
  ############################################
  # VIDEO WORKSHOP: INSERT vcl_recv CODE HERE
  ############################################


  ############################################
  # END VIDEO WORKSHOP
  ############################################
````


There is also a folder called `workshop-1` which contains our configurations for logging. 


Add the contents from `vcl_recv.vcl` from this directory in your repo into this section. It should look like this at the end:

````
  ############################################
  # VIDEO WORKSHOP: INSERT vcl_recv CODE HERE
  ############################################


  # Record number of retrans on the connection
  set req.http.total_retrans = client.socket.tcpi_total_retrans;
=======
 
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
````

Next, add the logging configuration to the rest of the sections in our VCL:

* `vcl_miss` (`vcl_miss.vcl`)
* `vcl_pass` (`vcl_pass.vcl`) 
* `vcl_fetch` (`vcl_fetch.vcl`)
* `vcl_deliver` (`vcl_deliver.vcl`)
* `vcl_error` (`vcl_error.vcl`)
* `vcl_log` (`vcl_log.vcl`)

### Step 3: Upload and activate configuration

Save your updated configuration as `workshop1.vcl`. Now, upload this file as your new main configuration:

````
curl -X POST https://api.fastly.com/service/${SERVICE_ID}/version/2/vcl -H "Fastly-Key:${API_KEY}" -H 'content-type: multipart/form-data' --data "name=workshop1&main=true" --data-urlencode "content@workshop1.vcl" | jq
````

Your response should look something like this:

````
{
  "name": "workshop1",
  "main": true,
  "service_id": "2KVPqlEPCh6tRCVQBxlUYk",
  "version": 12,
  "content": "",
  "deleted_at": null,
  "created_at": "2018-09-08T15:32:34Z",
  "updated_at": "2018-09-08T15:32:34Z"
}
````

Finally, activate version 2 to be the new active version:

````
curl -X PUT https://api.fastly.com/service/${SERVICE_ID}/version/2/activate -H "Fastly-Key: ${API_KEY}" | jq
````

<a id="workshop2"></a>
## Workshop 2: VOD Optimizations

In this workshop we are testing a progressive download of a video, then adding optimizations a configuration to increase performance of the progressive download.

### Step 1: Testing download

For this, we will use curl with some tweaks to gauge performance.

In bash, use this command set an alias for curl, with timing indicators and the Fastly debug header to see extra information about the request:

````
alias curltest="curl -w '\nLookup time:\t%{time_namelookup}\nConnect time:\t%{time_connect}\nApp Con time:\t%{time_appconnect}\nPreXfer time:\t%{time_pretransfer}\nRedirect time:\t%{time_redirect}\nStartXfer time:\t%{time_starttransfer}\n\nTotal time:\t%{time_total}\n' -svo /dev/null -H 'Fastly-Debug: 1'"
````

We can then download our video as such (replacing `<num>` with the number of your assigned service.:

````
curltest https://<num>-videoworkshop.global.ssl.fastly.net/vod/zz_top/720p.mp4
````

You should receive an output like this:

````
Lookup time:	0.067303
Connect time:	0.081613
App Con time:	0.145351
PreXfer time:	0.145988
Redirect time:	0.000000
StartXfer time:	0.429937

Total time:	12.066361

real	0m12.087s
user	0m0.563s
sys	   0m0.561s
````

### Step 2: Cloning new service version

First, lets clone our service, From version 2 to version 3

````
curl -H "Fastly-Key: ${API_KEY}" -X PUT https://api.fastly.com/service/${SERVICE_ID}/version/2/clone | jq
````

### Step 3: Adding configuration optimizations

Now, lets go back to our `workshop1.vcl` file, and start adding our VOD optimizations.

You will find a directory called `workshop-2` in your repo, this contains the configuration optimizations for this workshop.

Now, open the file `vod-vcl_fetch.vcl`, and add the VCL into the secion in `vcl_fetch` in your config.

In this section, we've added several options.

1. Set a low TTL (1 second) on any HTTP status that doesnt match a successful 2xx HTTP code (200, 206)
2. Enabled "streaming miss" on files with specific extension, to start streaming the file immediately to end user.
3. Checked our header set before to ensure we are working with VOD content, and adding `stale-if-error` and `stale-while-revalidate` headers to continue serving  expired content in the event the origin is unavailable.

It should look like this after adding (*above* our logging configuration):

````
  ############################################
  # VIDEO WORKSHOP: INSERT vcl_fetch CODE HERE
  ############################################

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
  if(req.http.X-Service == "vod") {

    /* set stale_if_error and stale_while_revalidate (customize these values) */
    set beresp.stale_if_error = 7d;
    set beresp.stale_while_revalidate = 60s;

    # Cache VOD content for 1 year
    set beresp.ttl = 365d;
  }

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

  ############################################
  # END VIDEO WORKSHOP
  ############################################
````

Finally, we can add our TCP optimisations in `vcl_deliver`. These can be found in the `vod-vcl_deliver.vcl` file. Place this above the logging configuration done previously:

````
  ############################################
  # VIDEO WORKSHOP: INSERT vcl_deliver CODE HERE
  ############################################

  # increase init cwnd
=======
  
  # increase init cwnd and use BBR
  if (client.requests == 1) {
    set client.socket.cwnd = 45;
    set client.socket.congestion_algorithm = "bbr";
  }

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

  ############################################
  # END VIDEO WORKSHOP
  ############################################
````

### Step 4: Uploading and activating our new configuration

We can now use the Fastly API to upload our configuration and activate it. It should activate globally ithin a few seconds.

Save your `workshop1.vcl` file as `workshop2.vcl`, ready for upload.

In order to upload VCL we must URL encode the file so that we can send it via Curl:

````
curl -H "Fastly-Key: ${API_KEY}" -X POST -H "Content-Type: application/x-www-form-urlencoded" --data "name=workshop2&main=true" --data-urlencode "content@workshop2.vcl" https://api.fastly.com/service/${SERVICE_ID}/version/3/vcl | jq
````

You should receive a response like this. It will container all the VCL from your upload so the response is quire large. This is a sanitized version:

````
{
  "name": "workshop2",
  "main": true,
  "content": "<lots of VCL>,
  "service_id": "1OPpKYvOlWVx37twfGVsq0",
  "version": 3,
  "deleted_at": null,
  "created_at": "2017-06-20T20:23:52+00:00",
  "updated_at": "2017-06-20T20:23:52+00:00"
}
````

Now, let's activate the version we are working on:

````
curl -H "Fastly-Key: ${API_KEY}" -X PUT https://api.fastly.com/service/${SERVICE_ID}/version/3/activate | jq
````

### Step 5: Purge our URL and re-download.

Now, lets purge the file we downloaded from cache so we can test a fresh download. Use cURL for the following command, again updating URL with your specific service number

````
curl -X PURGE https://<num>-videoworkshop.global.ssl.fastly.net/vod/zz_top/720p.mp4
````

Now, we can test the performance of the download again:

````
curltest https://<num>-videoworkshop.global.ssl.fastly.net/vod/zz_top/720p.mp4
````

You should see a faster download after these changes. We will explore these more in our Sumo dashboard as well.

<a id="workshop3"></a>
## Workshop 3: Live Optimizations

In this workshop we will be adding specific configurations to optimize live delivery.

### Step 1: Add new Live origin server
First, lets clone our service to a new version, this time version 4:

````
curl -H "Fastly-Key: ${API_KEY}" -X PUT https://api.fastly.com/service/${SERVICE_ID}/version/3/clone | jq
````

Next, use the API to configure a new backend server.

* IP/Hostname: `35.237.107.155`
* Name: `live`

````
curl -H "Fastly-Key: ${API_KEY}" -X POST -H "Content-Type: application/x-www-form-urlencoded" --data "ipv4=35.230.111.226&name=live" https://api.fastly.com/service/${SERVICE_ID}/version/4/backend | jq
````

### Step 2: Add live optimizations

Open up your `workshop2.vcl` file again. This time we are working with optimizations from the `workshop3` folder in your repo. In the `vcl_recv` section, add the code from the `live-vcl_recv.vcl` file into the worksop section.

The changes we are making:

1. Adding a conditional for our live backend based on path `/live`
2. Updating URL structure to something the origin can understand (origin endpoint is `/hls`).
3. Setting our header to use later for live `X-service: live`.

It should look like this at the end (with VOD and Live changes:

````

  if(req.url.path ~ "^/vod") {
    set req.backend = F_google;
    set req.url = regsub(req.url, "/vod", "/fastly-avalanche/videos");
    set req.http.Host = "storage.googleapis.com";
    set req.http.X-Service = "vod";
  }

  ############################################
  # VIDEO WORKSHOP: INSERT vcl_recv CODE HERE
  ############################################

  if(req.url.path ~ "^/live") {
    set req.backend = F_live;
    set req.url = regsub(req.url, "/live", "/hls");
    set req.http.X-Service = "live";
  }

  ######## vcl_recv ###########

  # Record number of retrans on the connection
  set req.http.total_retrans = client.socket.tcpi_total_retrans;
  ###############################

  ############################################
  # END VIDEO WORKSHOP
  ############################################
````

Next, we'll set caching behavior for our live stream in `vcl_fetch`. Copy the contents of the file `live-vcl_fetch.vcl` and add to the workshop section.

In this section:

1. We are setting specific TTLs for our live segments. 1 second for our manifest files, and 1 hour for our segment files.

It should end up looking like this:

````
  ############################################
  # VIDEO WORKSHOP: INSERT vcl_fetch CODE HERE
  ############################################

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
  if(req.http.X-Service == "vod") {

    /* set stale_if_error and stale_while_revalidate (customize these values) */
    set beresp.stale_if_error = 7d;
    set beresp.stale_while_revalidate = 60s;

    # Cache VOD content for 1 year
    set beresp.ttl = 365d;
  }

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

  ############################################
  # END VIDEO WORKSHOP
  ############################################
````

### Step 3: Uploading and activating our new configuration

Now, save configuration as `workshop3.vcl`, and upload/activate our configuration like before:

````
curl -H "Fastly-Key: ${API_KEY}" -X POST -H "Content-Type: application/x-www-form-urlencoded" --data "name=workshop3&main=true" --data-urlencode "content@workshop3.vcl" https://api.fastly.com/service/${SERVICE_ID}/version/4/vcl | jq
````

And activate:

````
curl -H "Fastly-Key: ${API_KEY}" -X PUT https://api.fastly.com/service/${SERVICE_ID}/version/4/activate | jq
````

### Step 4: Play our live stream

Now we have our config, lets open a media player (VLC works great for this) - or Safari native

Open VLC, and hit command+N (or ctrl-N for windows / linux)

Add the following URL into the network tab (making sure to update the assigned number to your service):

````
https://<num>-videoworkshop.global.ssl.fastly.net/live/altitude.m3u8
````

You should see a screen pop up and play the live stream.






