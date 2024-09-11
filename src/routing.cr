require "./http-errors"

module Routing
  extend self
  @@exit_nodes = Array(String).new

  def reload_exit_nodes
    LOGGER.debug "Updating Tor exit nodes array"
    @@exit_nodes = Utils.load_tor_exit_nodes
    LOGGER.debug "IPs inside the exit nodes array: #{@@exit_nodes.size}"
  end

  before_post "/api/admin/*" do |env|
    if env.request.headers.try &.["X-Api-Key"]? != CONFIG.adminApiKey || nil
      halt env, status_code: 401, response: error401("Wrong API Key")
    end
  end

  before_post do |env|
    if env.request.headers.try &.["X-Api-Key"]? == CONFIG.adminApiKey
      # Skips Tor and Rate limits if the API key matches
      next
    end
    if CONFIG.blockTorAddresses && @@exit_nodes.includes?(Utils.ip_address(env))
      halt env, status_code: 401, response: error401(CONFIG.torMessage)
    end
    # There is a better way to do this
    if env.request.resource == "/upload"
      begin
        ip_info = SQL.query_all("SELECT ip, count, date FROM #{CONFIG.ipTableName} WHERE ip = ?", Utils.ip_address(env), as: {ip: String, count: Int32, date: Int32})[0]
        time_since_first_upload = Time.utc.to_unix - ip_info[:date]
        time_until_unban = ip_info[:date] - Time.utc.to_unix + CONFIG.rateLimitPeriod
        if time_since_first_upload > CONFIG.rateLimitPeriod
          SQL.exec "DELETE FROM #{CONFIG.ipTableName} WHERE ip = ?", ip_info[:ip]
        end
        if ip_info[:count] >= CONFIG.filesPerIP && time_since_first_upload < CONFIG.rateLimitPeriod
          halt env, status_code: 401, response: error401("Rate limited! Try again in #{time_until_unban} seconds")
        end
      rescue ex
        LOGGER.error "Error when trying to enforce rate limits: #{ex.message}"
        next
      end
    end
  end

  def register_all
    get "/" do |env|
      host = Utils.host(env)
      files_hosted = SQL.query_one "SELECT COUNT (filename) FROM #{CONFIG.dbTableName}", as: Int32
      render "src/views/index.ecr"
    end

    post "/upload" do |env|
      Handling.upload(env)
    end

    get "/upload" do |env|
      Handling.upload_url(env)
    end

    post "/api/uploadurl" do |env|
      Handling.upload_url_bulk(env)
    end

    get "/:filename" do |env|
      Handling.retrieve_file(env)
    end

    get "/thumbnail/:thumbnail" do |env|
      Handling.retrieve_thumbnail(env)
    end

    get "/delete" do |env|
      Handling.delete_file(env)
    end

    get "/api/stats" do |env|
      Handling.stats(env)
    end

    get "/sharex.sxcu" do |env|
      Handling.sharex_config(env)
    end

    if CONFIG.adminEnabled
      self.register_admin
    end
  end

  def register_admin
    #   post "/api/admin/upload" do |env|
    #     Handling::Admin.delete_ip_limit(env)
    #   end
    post "/api/admin/delete" do |env|
      Handling::Admin.delete_file(env)
    end
  end

  post "/api/admin/deleteiplimit" do |env|
    Handling::Admin.delete_ip_limit(env)
  end

  post "/api/admin/fileinfo" do |env|
    Handling::Admin.retrieve_file_info(env)
  end

  get "/api/admin/torexitnodes" do |env|
    Handling::Admin.retrieve_tor_exit_nodes(env, @@exit_nodes)
  end
end
