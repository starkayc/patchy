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

# https://github.com/iv-org/invidious/blob/90e94d4e6cc126a8b7a091d12d7a5556bfe369d5/src/invidious.cr#L78
CURRENT_BRANCH  = {{ "#{`git branch | sed -n '/* /s///p'`.strip}" }}
CURRENT_COMMIT  = {{ "#{`git rev-list HEAD --max-count=1 --abbrev-commit`.strip}" }}
CURRENT_VERSION = {{ "#{`git log -1 --format=%ci | awk '{print $1}' | sed s/-/./g`.strip}" }}

Utils.create_db
Utils.create_files_dir

get "/" do |env|
  files_hosted = SQL.query_one "SELECT COUNT (filename) FROM files", as: Int32
  host = env.request.headers["Host"]
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

{% if flag?(:release) || flag?(:production) %}
  Kemal.config.env = "production" if !ENV.has_key?("KEMAL_ENV")
{% end %}
