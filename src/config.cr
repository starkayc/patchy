require "yaml"

class Config
  include YAML::Serializable
  # Colorize logs
  property colorize_logs : Bool = true
  # Log level
  property log_level : LogLevel = LogLevel::Info

  # Port on which the uploader will bind
  property port : Int32 = 8080
  # IP address on which the uploader will bind
  property host : String = "127.0.0.1"

  # Where the uploaded files will be located
  property files : String = "./files"
  # Where the thumbnails will be located when they are successfully generated
  property thumbnails : String = "./thumbnails"
  # Generate thumbnails for OpenGraph compatible platforms like Chatterino
  # Whatsapp, Facebook, Discord, etc.
  property generate_thumbnails : Bool = false
  # Where the SQLITE3 database will be located
  property db : String = "./db.sqlite3"

  # Enable or disable the admin API
  property admin_enabled : Bool = false
  # The API key for admin routes. It's passed as a "X-Api-Key" header to the
  # request
  property admin_api_key : String? = nil

  # Not implemented
  property incrementalfilename_length : Bool = true
  # Filename length
  property filename_length : Int32 = 3
  # In MiB
  property size_limit : Int16 = 512
  property enable_checksums : Bool = true

  # A file path where do you want to place a unix socket (THIS WILL DISABLE ACCESS
  # BY IP ADDRESS)
  property unix_socket : String?

  # True if you want this program to block IP addresses coming from the Tor
  # network
  property block_tor_addresses : Bool = false
  # How often (in seconds) should this program download the exit nodes list
  property tor_exit_nodes_check : Int32 = 3600
  # Only https://check.torproject.org/exit-addresses is supported
  property tor_exit_nodes_url : String = "https://check.torproject.org/exit-addresses"
  # Message that will be displayed to the Tor user.
  # It will be shown on the Frontend and shown in the error 401 when a user
  # tries to upload a file using curl or any other tool
  property tor_message : String? = "Tor is blocked!"

  # How many files an IP address can upload to the server. Setting this to 0
  # disables rate limits in the rate limit period
  property files_per_ip : Int32 = 32
  # How often is the file limit per IP reset? (in seconds)
  property rate_limit_period : Int32 = 600
  # TODO: UNUSED CONSTANT
  property rate_limit_message : String = ""

  # Delete the files after how many days?
  property delete_files_after : Int32 = 14
  # How often should the check of old files be performed? (in seconds)
  property delete_files_check : Int32 = 1800
  # The lenght of the delete key
  property delete_key_length : Int32 = 6

  property site_info : String = "xd"
  # TODO: UNUSED CONSTANT
  property site_warning : String? = ""

  # Blocked extensions that are not allowed to be uploaded to the server
  property blocked_extensions : Array(String) = [] of String

  # A list of OpenGraph user agents. If the request contains one of those User
  # agents when trying to retrieve a file from the server; the server will
  # reply with an HTML with OpenGraph tags, pointing to the media thumbnail
  # (if it was generated successfully) and the name of the file as title
  property opengraph_useragents : Array(String) = [] of String

  # Since this program detects the Host header of the client it can be used
  # with multiple domains. You can display the domains in the frontend
  # and in `/api/stats`
  property alternative_domains : Array(String) = [] of String

  def self.check_config(config : Config)
    if config.filename_length <= 0
      puts "Config: filename_length cannot be less or equal to 0"
      exit(1)
    end

    if config.files.ends_with?('/')
      config.files = config.files.chomp('/')
    end
    if config.thumbnails.ends_with?('/')
      config.thumbnails = config.thumbnails.chomp('/')
    end
  end

  def self.load(config_file : String = "config/config.yml")
    config_yaml = File.read(config_file)
    config = Config.from_yaml(config_yaml)
    check_config(config)
    config
  end
end
