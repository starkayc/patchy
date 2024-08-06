macro error401(message)
    env.response.content_type = "application/json"
    env.response.status_code = 401
    error_message = {"error" => {{message}}}.to_json
    return error_message
  end

macro error403(message)
    env.response.content_type = "application/json"
    env.response.status_code = 403
    error_message = {"error" => {{message}}}.to_json
    return error_message
  end

macro error404(message)
    env.response.content_type = "application/json"
    env.response.status_code = 404
    error_message = {"error" => {{message}}}.to_json
    return error_message
  end

macro error413(message)
    env.response.content_type = "application/json"
    env.response.status_code = 413
    error_message = {"error" => {{message}}}.to_json
    return error_message
  end

macro error500(message)
    env.response.content_type = "application/json"
    env.response.status_code = 500
    error_message = {"error" => {{message}}}.to_json
    return error_message
  end

macro msg(message)
  env.response.content_type = "application/json"
  msg = {"message" => {{message}}}.to_json
  return msg
end
