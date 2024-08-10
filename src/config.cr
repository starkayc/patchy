require "yaml"

class Config
  include YAML::Serializable

  property files : String = "./files"
  property thumbnails : String = "./thumbnails"
  property generate_thumbnails : Bool = false
  property db : String = "./db.sqlite3"
  property db_table_name : String = "files"
  property incremental_filename_length : Bool = true
  property filename_length : Int32 = 3
  # In MiB
  property size_limit : Int16 = 512
  property port : Int32 = 8080
  property unix_socket : String?
  property delete_files_after : Int32 = 7
  # How often should the check of old files be performed? (in seconds)
  property delete_files_after_check_seconds : Int32 = 1800
  property delete_key_length : Int32 = 4
  # Blocked extensions that are not allowed to be uploaded to the server
  property blocked_extensions : Array(String) = [] of String
  property siteInfo : String = "xd"
  property siteWarning : String? = ""
  property log_level : LogLevel = LogLevel::Info

  def self.load
    config_file = "config/config.yml"
    config_yaml = File.read(config_file)
    config = Config.from_yaml(config_yaml)
    check_config(config)
    config
  end

  def self.check_config(config : Config)
    if config.filename_length <= 0
      puts "Config: filename_length cannot be #{config.filename_length}"
      exit(1)
    end
  end
end
