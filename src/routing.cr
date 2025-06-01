require "./macros"
require "./exceptions"
require "./routes/**"
require "./operations/*"

module Routing
  extend self

  private ADMIN_API_ROUTE_PATH = "/-/api/admin"

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

  before_all do |env|
    env.set "host", env.request.headers["X-Forwarded-Host"]? || env.request.headers["Host"]? || nil
    env.set "scheme", env.request.headers["X-Forwarded-Proto"]? || "http"
    env.set "ip", env.request.headers["X-Real-IP"]? || env.request.remote_address.as?(Socket::IPAddress).try &.address || nil

    if env.request.resource.starts_with?(ADMIN_API_ROUTE_PATH)
      env.response.content_type = "application/json"

      api_key = env.request.headers["X-Api-Key"]?

      res = {"error" => "Wrong API Key"}.to_json
      if api_key != CONFIG.admin_api_key
        halt env, status_code: 401, response: res
      end
    end
  end

  private def before_upload(env)
    tor_exit_nodes = Utils::Tor.exit_nodes
    ip = Headers.ip_addr
    api_key = env.request.headers["X-Api-Key"]?

    # Skips Tor blocking and Rate limits if the API key matches
    return if api_key == CONFIG.admin_api_key

    if CONFIG.block_tor_addresses && tor_exit_nodes.includes?(ip)
      ee 401, CONFIG.tor_message
    end

    if !ip
      ee 401, "X-Real-IP header not present. Contact the admin to fix this!"
    end

    ip_info = Database::IP.select(ip)
    return if ip_info.nil?

    if CONFIG.files_per_ip > 0
      time_since_first_upload = Time.utc.to_unix - ip_info.date
      time_until_unban = ip_info.date - Time.utc.to_unix + CONFIG.rate_limit_period

      if time_since_first_upload > CONFIG.rate_limit_period
        Database::IP.delete(ip_info.ip)
      end

      if ip_info.count >= CONFIG.files_per_ip && time_since_first_upload < CONFIG.rate_limit_period
        ee 401, "Rate limited! Try again in #{time_until_unban} seconds"
      end
    end
  end

  before_post "/upload" { |env| before_upload(env) }
  before_post "/-/upload" { |env| before_upload(env) }

  def register_all
    # Views
    get "/", Routes::Views, :root
    get "/:filename", Routes::Views, :show_file
    get "/-/info/configs", Routes::Views, :uploader_configs
    get "/-/admin", Routes::Views, :admin
    get "/-/login", Routes::Views, :login
    get "/-/reportabuse", Routes::Views, :reportabuse

    # Upload
    post "/upload", Routes::Upload, :upload
    post "/-/upload", Routes::Upload, :upload

    # Retrieve
    get "/-/file/:filename", Routes::Retrieve, :retrieve_file
    get "/-/thumbnail/:thumbnail", Routes::Retrieve, :retrieve_thumbnail

    # Delete
    get "/-/delete", Routes::Delete, :delete_file

    # Misc
    get "/-/api/stats", Routes::Misc, :stats
    get "/-/info/sharex.sxcu", Routes::Misc, :sharex_config

    self.register_admin if CONFIG.admin_enabled
  end

  def register_admin
    post "#{ADMIN_API_ROUTE_PATH}/delete", Routes::Admin, :delete_file
    post "#{ADMIN_API_ROUTE_PATH}/fileinfo", Routes::Admin, :retrieve_file_info
    get "#{ADMIN_API_ROUTE_PATH}/torexitnodes", Routes::Admin, :tor_exit_nodes
    get "#{ADMIN_API_ROUTE_PATH}/cachedfiles", Routes::Admin, :cached_files
  end
end
