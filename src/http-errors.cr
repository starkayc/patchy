macro http_error(status_code, message)
  env.response.content_type = "application/json"
  env.response.status_code = {{status_code}}
  error_message = {"error" => {{message}}}.to_json    
  error_message
end

macro error400(message)
  http_error(400, {{message}})
end

macro error401(message)
  http_error(401, {{message}})
end

macro error403(message)
  http_error(403, {{message}})
end

macro error404(message)
  http_error(404, {{message}})
end

macro error413(message)
  http_error(413, {{message}})
end

macro error500(message)
  http_error(500, {{message}})
end

macro msg(message)
  env.response.content_type = "application/json"
  msg = {"message" => {{message}}}.to_json
  msg
end
