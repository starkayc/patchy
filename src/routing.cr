require "./http-errors"

macro ip_address
  env.request.headers.try &.["X-Forwarded-For"]? || env.request.remote_address.to_s.split(":").first
end

macro protocol
  env.request.headers.try &.["X-Forwarded-Proto"]? || "http"
end

macro host
  env.request.headers.try &.["X-Forwarded-Host"]? || env.request.headers["Host"]
end

module Routing
  extend self
  @@exit_nodes = Array(String).new
  if CONFIG.blockTorAddresses
    spawn do
      # Wait a little for Utils.retrieve_tor_exit_nodes to execute first
      # or it will load an old exit node list
      # I think this can be replaced by channels which makes me able to
      # receive data from fibers
      sleep 5
      loop do
        LOGGER.debug "Updating Tor exit nodes array"
        @@exit_nodes = Utils.load_tor_exit_nodes
        sleep CONFIG.torExitNodesCheck + 5
      end
    end
    before_post do |env|
      if @@exit_nodes.includes?(ip_address)
        halt env, status_code: 401, response: error401(CONFIG.torMessage)
      end
    end
  end

  def register_all
    get "/" do |env|
      files_hosted = SQL.query_one "SELECT COUNT (filename) FROM files", as: Int32
      render "src/views/index.ecr"
    end

    post "/upload" do |env|
      Handling.upload(env)
    end

    post "/api/uploadurl" do |env|
      Handling.upload_url(env)
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

    self.register_admin
  end

  def register_admin
    if CONFIG.adminEnabled
      post "/api/admin/delete" do |env|
        Handling::Admin.delete_file(env)
      end
    end
  end
end
