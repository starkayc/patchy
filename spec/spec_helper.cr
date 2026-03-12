require "spec"
require "kemal"
require "db"
require "spectator"

require "../src/config"
require "../src/logger"

require "../src/types/*"
require "../src/utils/*"

CONFIG = Config.load
LOGGER = LogHandler.new(STDOUT, CONFIG.log_level, CONFIG.colorize_logs)
