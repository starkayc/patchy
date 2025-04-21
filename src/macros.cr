macro ee(status_code, message)
  env.response.content_type = "application/json"
  env.response.status_code = {{status_code}}
  msg = {"error" => {{message}}}.to_json
  return msg
end

macro msg(message)
  env.response.content_type = "application/json"
  msg = {"message" => {{message}}}.to_json
  return msg
end

module Headers
  macro host
    env.request.headers["X-Forwarded-Host"]?
  end

  macro scheme
    env.request.headers["X-Forwarded-Proto"]?
  end

  macro ip_addr
    env.request.headers["X-Real-IP"]?
  end
end
