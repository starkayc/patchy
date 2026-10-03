macro ee(status_code, message)
  env.response.content_type = "application/json"
<<<<<<< HEAD
  env.response.status_code = {{status_code}}
  msg = {"error" => {{message}}}.to_json
=======
  env.response.status_code = {{ status_code }}
  msg = {"error" => {{ message }}}.to_json
>>>>>>> upstream/master
  # We close the response instantly
  # https://github.com/kemalcr/kemal/issues/249#issuecomment-259763562
  env.response.print msg
  env.response.close
  return
end

macro msg(message)
  env.response.content_type = "application/json"
<<<<<<< HEAD
  msg = {"message" => {{message}}}.to_json
=======
  msg = {"message" => {{ message }}}.to_json
>>>>>>> upstream/master
  # We close the response instantly
  # https://github.com/kemalcr/kemal/issues/249#issuecomment-259763562
  env.response.print msg
  env.response.close
  return
end

macro haltf(env, status_code = 200, response = "")
<<<<<<< HEAD
  {{env}}.response.status_code = {{status_code}}
  {{env}}.response.print {{response}}
  {{env}}.response.close
=======
  {{ env }}.response.status_code = {{ status_code }}
  {{ env }}.response.print {{ response }}
  {{ env }}.response.close
>>>>>>> upstream/master
  return
end

# https://github.com/iv-org/invidious/blob/4b37d47ebbc4d3a0a55c8febaca2b28a68e1d9b5/src/invidious/helpers/macros.cr#L51
# https://kemalcr.com/guide/#views-templates
macro templated(_filename, template = "template", navbar_search = true, buffer_footer = false)
<<<<<<< HEAD
  navbar_search = {{navbar_search}}
  buffer_footer = {{buffer_footer}}
=======
  navbar_search = {{ navbar_search }}
  buffer_footer = {{ buffer_footer }}
>>>>>>> upstream/master

  {{ filename = "src/views/" + _filename + ".ecr" }}
  {{ layout = "src/views/" + template + ".ecr" }}

<<<<<<< HEAD
  __content_filename__ = {{filename}}
  render {{filename}}, {{layout}}
=======
  __content_filename__ = {{ filename }}
  render {{ filename }}, {{ layout }}
>>>>>>> upstream/master
end

macro nodeProperties
  private MODULE_NAME = {{ @type.name.stringify }}
  private TABLE_NAME = {{ @type.name.stringify.split("::").last.downcase }}
end

module Headers
  macro locale
    env.request.headers["Accept-Language"]?.try &.split(",")[0].split(";")[0]
  end

  macro if_none_match
    env.request.headers["If-None-Match"]?
  end

  macro host
    env.get("host").as(String)
  end

  macro scheme
    env.get("scheme").as(String)
  end

  macro ip_addr
    env.get("ip").as(String)
  end

  macro user_agent
    env.get("user_agent").as(String)
  end
<<<<<<< HEAD
=======

  macro user_settings
    env.get("user_settings").as(::UserSettings)
  end
>>>>>>> upstream/master
end
