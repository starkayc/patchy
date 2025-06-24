require "http"
require "kemal"
require "yaml"
require "db"
require "sqlite3"
require "digest"
require "baked_file_handler"
require "baked_file_system"

# require "./ext/kemal_custom_exception_handler"

require "./logger"
require "./routing"
require "./config"
require "./jobs"
require "./utils/*"
require "./helpers/*"
require "./lib/*"
require "./types/*"
require "./database/*"

module Patchy
end

CONFIG = Config.load
Kemal.config.port = CONFIG.server.port
Kemal.config.host_binding = CONFIG.server.host
Kemal.config.shutdown_message = false
Kemal.config.app_name = "Patchy"
Kemal.config.powered_by_header = false
# https://github.com/iv-org/invidious/blob/90e94d4e6cc126a8b7a091d12d7a5556bfe369d5/src/invidious.cr#L136C1-L136C61
LOGGER = LogHandler.new(STDOUT, CONFIG.log_level, CONFIG.colorize_logs)
# Show current configuration
LOGGER.debug("Current configuration: \n#{CONFIG.to_yaml}")

Utils.create_db_dir
SQL = DB.open("sqlite3://#{CONFIG.db}/db.sqlite3")

# https://github.com/iv-org/invidious/blob/90e94d4e6cc126a8b7a091d12d7a5556bfe369d5/src/invidious.cr#L78
CURRENT_BRANCH  = {{ "#{`git branch | sed -n '/* /s///p'`.strip}" }}
CURRENT_COMMIT  = {{ "#{`git rev-list HEAD --max-count=1 --abbrev-commit`.strip}" }}
CURRENT_VERSION = {{ "#{`git log -1 --format=%ci | awk '{print $1}' | sed s/-/./g`.strip}" }}

# Taken from invidious!
# This is used to determine the `?v=` on the end of file URLs (for cache busting). We
# only need to expire modified assets, so we can use this to find the last commit that changes
# any assets
ASSET_COMMIT    = {{ "#{`git rev-list HEAD --max-count=1 --abbrev-commit -- public/-/assets/`.strip}" }}

Utils.check_dependencies
Utils.create_tables
Utils.create_files_dir
Utils.create_thumbnails_dir
Routing.register_all

{% if flag?(:release) || flag?(:production) %}
  Kemal.config.env = "production" if !ENV.has_key?("KEMAL_ENV")
{% end %}

Jobs.run

sleep
