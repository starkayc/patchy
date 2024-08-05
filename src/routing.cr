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

    get "/:filename" do |env|
      Handling.retrieve_file(env)
    end

    get "/delete" do |env|
      Handling.delete_file(env)
    end

    get "/stats" do |env|
      Handling.stats(env)
    end
  end
end
