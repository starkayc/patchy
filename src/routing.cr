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

  #   if env.request.headers.try &.["X-Api-Key"]? != CONFIG.adminApiKey || nil
  #     halt env, status_code: 401, response: "Wrong API Key"
  #   end
  # end

  before_post do |env|
    tor_exit_nodes = Utils::Tor.exit_nodes
    api_key = env.request.headers["X-Api-Key"]?

    # Skips Tor blocking and Rate limits if the API key matches
    if api_key == CONFIG.adminApiKey
      next
    end

    if CONFIG.blockTorAddresses && tor_exit_nodes.includes?(Headers.ip_addr)
      halt env, status_code: 401, response: CONFIG.torMessage
    end
  end

  before_post "/upload" do |env|
    begin
      ip_info = SQL.query_one?("SELECT ip, count, date FROM ips WHERE ip = ?", Headers.ip_addr, as: {ip: String, count: Int32, date: Int32})
    rescue ex
      LOGGER.error "Error when trying to enforce rate limits for ip #{Headers.ip_addr}: #{ex.message}"
      next
    end

    if ip_info.nil?
      next
    end

    time_since_first_upload = Time.utc.to_unix - ip_info[:date]
    time_until_unban = ip_info[:date] - Time.utc.to_unix + CONFIG.rateLimitPeriod
    if time_since_first_upload > CONFIG.rateLimitPeriod
      SQL.exec "DELETE FROM ips WHERE ip = ?", ip_info[:ip]
    end
    if CONFIG.filesPerIP > 0
      if ip_info[:count] >= CONFIG.filesPerIP && time_since_first_upload < CONFIG.rateLimitPeriod
        halt env, status_code: 401, response: "Rate limited! Try again in #{time_until_unban} seconds"
      end
    end
  end

  def register_all
    get "/", Routes::Views, :root
    get "/info/chatterino", Routes::Views, :chatterino

    post "/upload", Routes::Upload, :upload
    # get "/upload", Routes::Upload, :upload_url
    # post "/api/uploadurl", Routes::Upload, :upload_url

    get "/:filename", Routes::Retrieve, :retrieve_file
    get "/thumbnail/:thumbnail", Routes::Retrieve, :retrieve_thumbnail

    get "/delete", Routes::Deletion, :delete_file

    get "/api/stats", Routing::Misc, :stats
    get "/info/sharex.sxcu", Routing::Misc, :sharex_config
    get "/info/chatterinoconfig", Routing::Misc, :chatterino_config

    # if CONFIG.adminEnabled
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
