require "yaml"

class Config
  include YAML::Serializable

  property files : String = "./files"
  property db : String = "./db.sqlite3"
  property filename_lenght : Int8 = 3
  property port : UInt16 = 8080
  property unix_socket : String?
  property delete_files_after : Int32 = 7
  # How often should the check of old files be performed? (in seconds)
  property delete_files_after_check_seconds : Int32 = 60
  property delete_key_lenght : Int8 = 8

  def self.load
    config_file = "config/config.yml"
    config_yaml = File.read(config_file)
    config = Config.from_yaml(config_yaml)
    config
  end
end
