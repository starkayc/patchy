require "./macros"
require "./routes/**"

module Routing
  extend self

  {% for http_method in {"get", "post", "delete", "options", "patch", "put"} %}

    macro {{http_method.id}}(path, controller, method = :handle)
      unless Kemal::Utils.path_starts_with_slash?(\{{path}})
        raise Kemal::Exceptions::InvalidPathStartException.new({{http_method}}, \{{path}})
      end

      Kemal::RouteHandler::INSTANCE.add_route({{http_method.upcase}}, \{{path}}) do |env|
        \{{ controller }}.\{{ method.id }}(env)
      end
    end

  {% end %}

  # before_post "/api/admin/*" do |env|
  #   env.response.content_type = "application/json"

  #   if env.request.headers.try &.["X-Api-Key"]? != CONFIG.admin_api_key || nil
  #     halt env, status_code: 401, response: "Wrong API Key"
  #   end
  # end

  before_post do |env|
    tor_exit_nodes = Utils::Tor.exit_nodes
    api_key = env.request.headers["X-Api-Key"]?

    # Skips Tor blocking and Rate limits if the API key matches
    if api_key == CONFIG.admin_api_key
      next
    end

    if CONFIG.block_tor_addresses && tor_exit_nodes.includes?(Headers.ip_addr)
      halt env, status_code: 401, response: CONFIG.tor_message
    end
  end

  before_post "/upload" do |env|
    ip = Headers.ip_addr
    if !ip
      halt env, status_code: 401, response: "X-Real-IP header not present. Contact the admin to fix this!"
    end

    ip_info = Database::IP.select(ip)

    if ip_info.nil?
      next
    end

    if CONFIG.files_per_ip > 0
      time_since_first_upload = Time.utc.to_unix - ip_info.date
      time_until_unban = ip_info.date - Time.utc.to_unix + CONFIG.rate_limit_period

      if time_since_first_upload > CONFIG.rate_limit_period
        Database::IP.delete(ip_info.ip)
      end

      if ip_info.count >= CONFIG.files_per_ip && time_since_first_upload < CONFIG.rate_limit_period
        halt env, status_code: 401, response: "Rate limited! Try again in #{time_until_unban} seconds"
      end
    end
  end

  def register_all
    get "/", Routes::Views, :root
    get "/info/chatterino", Routes::Views, :chatterino

    post "/upload", Routes::Upload, :upload

    get "/:filename", Routes::Retrieve, :retrieve_file
    get "/thumbnail/:thumbnail", Routes::Retrieve, :retrieve_thumbnail

    get "/delete", Routes::Deletion, :delete_file

    get "/api/stats", Routing::Misc, :stats
    get "/info/sharex.sxcu", Routing::Misc, :sharex_config
    get "/info/chatterinoconfig", Routing::Misc, :chatterino_config

    # if CONFIG.admin_enabled
    #   self.register_admin
    # end
  end

  # def register_admin
  #   #   post "/api/admin/upload" do |env|
  #   #     Routes::Admin.delete_ip_limit(env)
  #   #   end
  #   post "/api/admin/delete" do |env|
  #     Routes::Admin.delete_file(env)
  #   end
  # end

  # post "/api/admin/deleteiplimit" do |env|
  #   Routes::Admin.delete_ip_limit(env)
  # end

  # post "/api/admin/fileinfo" do |env|
  #   Routes::Admin.retrieve_file_info(env)
  # end

  # get "/api/admin/torexitnodes" do |env|
  #   Routes::Admin.retrieve_tor_exit_nodes(env, @@exit_nodes)
  # end

  error 404 do |env|
    env.response.content_type = "text/plain"
    "File not found.\nArchivo no encontrado."
  end
end
