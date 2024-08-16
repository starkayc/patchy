require "yaml"

class Config
  include YAML::Serializable

  property files : String = "./files"
  property thumbnails : String = "./thumbnails"
  property generateThumbnails : Bool = false
  property db : String = "./db.sqlite3"
  property dbTableName : String = "files"
  property adminEnabled : Bool = false
  property adminApiKey : String? = ""
  # Not implemented
  property incrementalFileameLength : Bool = true
  property fileameLength : Int32 = 3
  # In MiB
  property size_limit : Int16 = 512
  property port : Int32 = 8080
  property unix_socket : String?
  property blockTorAddresses : Bool? = false
  property torExitNodesCheck : Int32 = 3600
  # The list needs to contain a IP address per line
  property torExitNodesUrl : String = "https://www.dan.me.uk/torlist/?exit"
  property torExitNodesFile : String = "./torexitnodes.txt"
  property filesPerIP : Int32 = 32
  property ipTableName : String = "ips"
  # How often is the file limit per IP reset?
  property rateLimitPeriod : Int32 = 600
  property torMessage : String? = "Tor is blocked!"
  property deleteFilesAfter : Int32 = 7
  # How often should the check of old files be performed? (in seconds)
  property deleteFilesCheck : Int32 = 1800
  property deleteKeyLength : Int32 = 4
  # Blocked extensions that are not allowed to be uploaded to the server
  property siteInfo : String = "xd"
  property siteWarning : String? = ""
  property log_level : LogLevel = LogLevel::Info
  property blockedExtensions : Array(String) = [] of String
  property opengraphUseragents : Array(String) = [] of String
  # Since this program detects the Host header of the client it can be used
  # with multiple domains. You can display the domains in the frontend
  # and in `/api/stats`
  property alternativeDomains : Array(String) = [] of String

  def self.load
    config_file = "config/config.yml"
    config_yaml = File.read(config_file)
    config = Config.from_yaml(config_yaml)
    check_config(config)
    config
  end

  def self.check_config(config : Config)
    if config.fileameLength <= 0
      puts "Config: fileameLength cannot be #{config.fileameLength}"
      exit(1)
    end
  end
end
