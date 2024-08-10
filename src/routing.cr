module Routing
  #   @@ip : String = ""

  def self.register_all
    # before_get "*" do |env|
    #   @@ip = env.request.headers["X-Real-IP"]
    # end

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
