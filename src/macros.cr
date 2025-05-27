macro ee(status_code, message)
  env.response.content_type = "application/json"
  env.response.status_code = {{status_code}}
  msg = {"error" => {{message}}}.to_json
  # We close the response instantly
  # https://github.com/kemalcr/kemal/issues/249#issuecomment-259763562
  env.response.print msg
  env.response.close
  return
end

macro msg(message)
  env.response.content_type = "application/json"
  msg = {"message" => {{message}}}.to_json
  return msg
end

# https://github.com/iv-org/invidious/blob/4b37d47ebbc4d3a0a55c8febaca2b28a68e1d9b5/src/invidious/helpers/macros.cr#L51
# https://kemalcr.com/guide/#views-templates
macro templated(_filename, template = "template", navbar_search = true, buffer_footer = false)
  navbar_search = {{navbar_search}}
  buffer_footer = {{buffer_footer}}

  {{ filename = "src/views/" + _filename + ".ecr" }}
  {{ layout = "src/views/" + template + ".ecr" }}

  __content_filename__ = {{filename}}
  render {{filename}}, {{layout}}
end

module Headers
  macro host
    env.get("host").as(String)
  end

  macro scheme
    env.get("scheme").as(String)
  end

  macro ip_addr
    env.get("ip").as(String)
  end
end
