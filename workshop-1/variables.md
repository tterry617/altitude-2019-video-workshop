# Visibility- Advanced logging variables for video
| Name | Example | Type | Unit | Description
-----------|-------|---------|-----------|---------
| timestamp|2019-07-11T14:25:24:955432Z|ISO 8601 datetime||Timestamp of the beginning of the request.
| client\_as\_number | 14618 | Integer | |User's Autonomous Service Number. ASN is a unique number used to identify service providers.
|client\_city|ashburn|String||User's city.
|client\_congestion\_algorithm|cubic|String||Congestion control algorithm for the client connection, "cubic" or "bbr".
|client\_country\_code|USA|String||User's three-character ISO 3166-1 alpha-3 country code.
|client\_cwnd|20|Integer|Packets|This is the size, in packets, of the current congestion window for sending data to the client.
|client\_delivery\_rate|260806|Integer|Bytes/second|The bitrate used to deliver the object from the Fastly POP to the user.
|client\_ip|54.90.79.113|IP address||User's IP address.
|client\_latitude|39.033|Float|Degrees|User's latitude, in units of degrees from the equator.
|client\_longitude|	-77.487|Float|Degrees|User's longitude, in units of degrees from the IERS Reference Meridian.
|client\_ploss	|0.000|Float|Percentage	|A very rough estimate of packet loss associated with the current HTTP request, from 0 (no loss) to 1 (only loss).
|client\_requests|1|Integer||The number of client-side HTTP requests that have been started on this same connection (including the current one) at the time this request was received.
|client\_retrans|0|Integer||The number of times packets had to be retransmitted in the course of delivering the requested object. Ideally this number should always be zero.
|client\_rtt|5|Integer|Milliseconds| Round Trip Time in milliseconds from the client to Fastly.
|fastly\_is\_edge|true|Boolean||Whether or not the request is being handled by an Edge POP.
|fastly\_is\_shield|false|Boolean	||Whether or not the request is being handled by a Shield POP.
|fastly\_pop|JFK|String||Which POP handled the inbound request from the user.
|fastly\_server|cache-jfk8129|String||Which node on the POP handled the request from the user.
|fastly\_shield\_used|JFK|String||Which POP is specified as the origin shield.
|origin\_host|www.example.com|String||Host name request header sent to the origin.
|origin\_ip|35.201.75.167|IP address	||IP address of the customer's origin used for this request. Especially useful when customers have multiple origins or their origins are fronted by a load balancer.
|origin\_method|GET|String||The request method sent to the origin.
|origin\_name|F\_origin\_0|String||The backend name used to talk to the customer's origin for this request. This can be useful when customers have multiple backends in their configuration.
|origin\_port|443|Integer||Port being used to talk to the customer's origin for this request.
|origin\_reason|OK|String||The origin's reason phrase.
|origin\_status|200|Integer||The origin's status code.
|origin\_ttfb	|158.590|Float duration	|Milliseconds|Time To First Byte from the origin to Fastly POP in milliseconds.
|origin\_ttlb|161.710|Float duration|Milliseconds|Time to Last Byte from origin to Fastly POP in milliseconds. For streaming miss, this is an approximation.
|origin\_url|/images/cat.jpg|String||The request URL path sent to the origin.
|request\_host|www.example.com|String||Host name request header.
|request\_is\_h2|false|Boolean||Whether or not this is an HTTP2 request.
|request\_is\_ipv6|false|Boolean||Whether or not this is an IPv6 request.
|request\_method|GET|String||The request method.
|request\_referer||String||Referer request header.
|request\_tls\_version|TLSv1.2|String||Which version of TLS the end user is using.
|request\_url|/images/cat.jpg|String	||URL path (everything after the host name, including query parameters)
|request\_user\_agent|Mozilla/5.0...	|String||User Agent request header.
|response\_age|13|Integer|Seconds|Total age of the object.
|response\_bytes|1717|Integer|Bytes|Total bytes delivered, including body and header.
|response\_bytes\_body|495|Integer|Bytes|Body bytes delivered.
|response\_bytes\_header|1222|Integer|Bytes|Header bytes delivered.
|response\_cache\_control|public, max-age=20|String||The Cache-Control response header.
|response\_completed|true|Boolean	||If the object was completely delivered or not. With Streaming Miss enabled, we log a 200 but that does not get updated if the object fails to deliver fully (for example the Time Between Bytes threshold is exceeded and causes Fastly to abandon the delivery).
|response\_content\_length|495|Integer|Bytes|The size reported by the object. The response\_bytes should be at least as big as this number. If it's not then the object was not delivered completely.
|response\_content_type|application/json|String|The content type of the response.
|response\_reason|OK|String||The reason phrase Fastly replied with.
|response\_state|MISS-CLUSTER|String||Tells if the object was a Hit or a Miss or a combination thereof because of origin shielding.
|response\_status|200|Integer||The status code Fastly replied with.
|response\_ttfb|235.288|Float duration|Milliseconds|Time to first byte for Varnish in milliseconds.
|response\_ttlb|20.235|Float duration|Milliseconds|Time to last byte for Varnish in milliseconds.
|response\_ttl|235.391|Float duration|Seconds|The amount of seconds the object will be cached by Fastly.
|response\_x\_cache|MISS, HIT|STRING||The X-Cache header which represents the HIT/MISS status of the edge and shield POPs.
