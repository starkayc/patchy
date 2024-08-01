require "http"
require "kemal"
require "yaml"
require "db"
require "sqlite3"
require "digest"

require "./utils"
require "./handling"
require "./lib/**"
require "./config"

CONFIG = Config.load
Kemal.config.port = CONFIG.port
SQL = DB.open("sqlite3://#{CONFIG.db}")

Utils.create_db
Utils.create_files_dir

get "/" do |env|
  render "src/views/index.ecr"
end

# TODO: Error checking later
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

CHECK_OLD_FILES = Fiber.new do
  loop do
    Utils.check_old_files
    sleep CONFIG.delete_files_after_check_seconds
  end
end

CHECK_OLD_FILES.enqueue
Kemal.run
