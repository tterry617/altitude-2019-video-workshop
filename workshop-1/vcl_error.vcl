  #### vcl_error ####

  # req.backend.is_origin is not available in vcl_error
  if (!req.backend.is_shield) {
    set obj.http.log-origin:shield = server.datacenter;
  }
  ###################