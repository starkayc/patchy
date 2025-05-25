require "./macros"
require "./routes/**"
require "./operations/*"

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

  before_all "/api/admin/*" do |env|
    env.response.content_type = "application/json"

    res = {"error" => "Wrong API Key"}.to_json
    if env.request.headers.try &.["X-Api-Key"]? != CONFIG.admin_api_key || nil
      halt env, status_code: 401, response: res
    end
  end

  before_post "/upload" do |env|
    tor_exit_nodes = Utils::Tor.exit_nodes
    ip = Headers.ip_addr
    api_key = env.request.headers["X-Api-Key"]?

    # Skips Tor blocking and Rate limits if the API key matches
    next if api_key == CONFIG.admin_api_key

    if CONFIG.block_tor_addresses && tor_exit_nodes.includes?(Headers.ip_addr)
      halt env, status_code: 401, response: CONFIG.tor_message
    end

    if !ip
      halt env, status_code: 401, response: "X-Real-IP header not present. Contact the admin to fix this!"
    end

    ip_info = Database::IP.select(ip)
    next if ip_info.nil?

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
    # Views
    get "/", Routes::Views, :root
    get "/-/info/configs", Routes::Views, :uploader_configs
    get "/-/admin", Routes::Views, :admin
    get "/-/login", Routes::Views, :login

    # Upload
    post "/upload", Routes::Upload, :upload
    post "/-/upload", Routes::Upload, :upload

    # Retrieve
    get "/:filename", Routes::Retrieve, :retrieve_file
    get "/-/thumbnail/:thumbnail", Routes::Retrieve, :retrieve_thumbnail

    # Delete
    get "/-/delete", Routes::Delete, :delete_file

    # Misc
    get "/-/api/stats", Routes::Misc, :stats
    get "/-/info/sharex.sxcu", Routes::Misc, :sharex_config

    self.register_admin if CONFIG.admin_enabled
  end

  def register_admin
    post "/-/api/admin/delete", Routes::Admin, :delete_file
    post "/-/api/admin/fileinfo", Routes::Admin, :retrieve_file_info
    get "/-/api/admin/torexitnodes", Routes::Admin, :tor_exit_nodes
    get "/-/api/admin/cachedfiles", Routes::Admin, :cached_files
  end
end
