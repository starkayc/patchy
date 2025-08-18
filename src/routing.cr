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
    env.set "user_agent", env.request.headers["User-Agent"]?

    env.response.headers["Content-Security-Policy"] = {
      "sandbox allow-popups allow-popups-to-escape-sandbox allow-downloads allow-scripts allow-same-origin",
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline'",
      "img-src 'self' data:",
      "media-src 'self' data:",
      "style-src 'self' 'unsafe-inline'",
      "font-src 'self' data:",
      "connect-src 'self'",
    }.join(";")

    if env.request.resource.starts_with?(ADMIN_API_ROUTE_PATH)
      env.response.content_type = "application/json"

      api_key = env.request.headers["X-Api-Key"]?

      res = {"error" => "Wrong API Key"}.to_json
      if api_key != CONFIG.admin_api_key
        halt env, status_code: 401, response: res
      end
    end
  end

  private def before_upload(env : HTTP::Server::Context) : Nil
    tor_exit_nodes = Utils::IpBlocks::Tor.exit_nodes
    vpn_ip_addresses = Utils::IpBlocks::VPN.ips
    ip = Headers.ip_addr
    api_key = env.request.headers["X-Api-Key"]?

    # Skips Tor blocking and Rate limits if the API key matches
    return if api_key == CONFIG.admin_api_key

    if tor_exit_nodes.includes?(ip)
      ee 401, "The administrator has blocked Tor exit nodes for uploading files"
    end

    if vpn_ip_addresses.includes?(ip)
      ee 401, "The administrator has blocked your VPN provider for uploading files"
    end

    if !ip
      ee 401, "X-Real-IP header not present. Contact the admin to fix this!"
    end

    ip_info = Database::IPS.select(ip)
    return if ip_info.nil?

    if CONFIG.files_per_ip > 0
      time_since_first_upload = Time.utc.to_unix - ip_info.date
      time_until_unban = ip_info.date - Time.utc.to_unix + CONFIG.rate_limit_period

      if time_since_first_upload > CONFIG.rate_limit_period
        Database::IPS.delete(ip_info.ip)
      end

      if ip_info.count >= CONFIG.files_per_ip && time_since_first_upload < CONFIG.rate_limit_period
        ee 401, "Rate limited! Try again in #{time_until_unban} seconds"
      end
    end
  end

  before_post "/upload" { |env| before_upload(env) }
  before_post "/-/upload" { |env| before_upload(env) }

  def register_all : Array(Radix::Node(Kemal::Route)) | Kemal::Route | Radix::Node(Kemal::Route) | Nil
    # Views
    get "/", Routes::Views, :root
    get "/:filename", Routes::Views, :show_file
    get "/-/info/configs", Routes::Views, :uploader_configs
    get "/-/info/history", Routes::Views, :upload_history
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

  def register_admin : Array(Radix::Node(Kemal::Route)) | Kemal::Route | Radix::Node(Kemal::Route) | Nil
    post "#{ADMIN_API_ROUTE_PATH}/delete", Routes::Admin, :delete_file
    post "#{ADMIN_API_ROUTE_PATH}/fileinfo", Routes::Admin, :retrieve_file_info
    get "#{ADMIN_API_ROUTE_PATH}/torexitnodes", Routes::Admin, :tor_exit_nodes
    get "#{ADMIN_API_ROUTE_PATH}/cachedfiles", Routes::Admin, :cached_files
  end
end
