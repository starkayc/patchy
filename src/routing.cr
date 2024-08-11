require "./http-errors"

module Routing
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
      ip_address = env.request.headers.try &.["X-Forwarded-For"]? ? env.request.headers.["X-Forwarded-For"] : env.request.remote_address.to_s.split(":").first
      if ip_address.includes?(ip_address)
        # TODO: Custom halt function to return a JSON
        halt env, status_code: 401, response: CONFIG.torMessage
      end
    end
  end

  def self.register_all
    get "/" do |env|
      files_hosted = SQL.query_one "SELECT COUNT (filename) FROM files", as: Int32
      host = env.request.headers["Host"]
      render "src/views/index.ecr"
    end

    post "/upload" do |env|
      Handling.upload(env)
    end

    post "/api/uploadurl" do |env|
      Handling.upload_url(env)
    end

    if CONFIG.adminEnabled
      post "/api/admin/delete" do |env|
        Handling::Admin.delete_file(env)
      end
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
  end
end
