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
    env.request.headers["X-Forwarded-Host"]? || env.request.headers["Host"]?
  end

  macro scheme
    env.request.headers["X-Forwarded-Proto"]? || "http"
  end

  macro ip_addr
    env.request.headers["X-Real-IP"]? || env.request.remote_address.as?(Socket::IPAddress).try &.address
  end
end
