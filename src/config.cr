require "yaml"

class Config
  include YAML::Serializable

  # Colorize logs
  property colorize_logs : Bool = true
  # Log level
  property log_level : LogLevel = LogLevel::Info

  property server : Server = Server.from_yaml("")

  struct Server
    include YAML::Serializable

    # Port on which the uploader will bind
    property port : Int32 = 8080
    # IP address on which the uploader will bind
    property host : String = "0.0.0.0"
    # A file path where do you want to place a unix socket (THIS WILL DISABLE ACCESS
    # BY IP ADDRESS)
    property unix_socket : String?
  end

  # Where the uploaded files will be located
  property files : String = "./data/files"
  # Where the thumbnails will be located when they are successfully generated
  property thumbnails : String = "./data/thumbnails"
  # Where the SQLITE3 database will be located
  property db : String = "./data/db"

  # Generate thumbnails for OpenGraph compatible platforms like Chatterino
  # Whatsapp, Facebook, Discord, etc.
  property thumbnail_generation : ThumbnailGeneration = ThumbnailGeneration.from_yaml("")

  struct ThumbnailGeneration
    include YAML::Serializable

    property enabled : Bool = false
  end

  property s3 : S3Config = S3Config.from_yaml("")

  struct S3Config
    include YAML::Serializable

    property enabled : Bool = false

    # Region can be anything if it's being used with Minio or Backblaze S3
    property region : String = ""
    property key : String = ""
    property secret : String = ""
    property endpoint : String = ""

    property bucket_name : String = "patchy"
  end

  # Uses more memory, but improves files retrieval and reduces stress
  # on the drive by caching the files into memory using LRU cache algorithm
  # If you are a techy person and you want to test if this works, then use
  # `sudo strace -e trace=open,openat -p $(pidof patchy)`
  # With cache disabled, it will open the file each time is being retrieved
  # by the client, and with cache enabled, the cached file will be read from
  # memory!!
  property cache : Cache = Cache.from_yaml("")

  struct Cache
    include YAML::Serializable

    property enabled : Bool = false
    # Number of files that can be cached
    property max_size : Int32 = 256
    # In KiB, files bigger than this will not be cached
    property max_allowed_filesize : Int32 = 512
  end

  property views : Views = Views.from_yaml("")

  struct Views
    include YAML::Serializable

    property site_info : String = "Welcome to Patchy - A temporary file uploader"

    property show_title : Bool = true
    property show_file_count : Bool = true
    property show_version : Bool = true

    property index_navbar : IndexNavbar = IndexNavbar.from_yaml("")

    struct IndexNavbar
      include YAML::Serializable

      property enabled : Bool = true
      property show_uploader_configs : Bool = true
      property show_upload_history : Bool = true
      property show_admin : Bool = true
      property show_login : Bool = true
    end

    property autoplay_video : Bool = false
    property autoplay_audio : Bool = false
  end

  # Enable or disable the admin API
  property admin_enabled : Bool = false
  # The API key for admin routes. It's passed as a "X-Api-Key" header to the
  # request
  property admin_api_key : String? = nil

  # Not implemented
  property incremental_filename_length : Bool = true
  # Filename length
  property filename_length : Int32 = 3
  # In MiB
  property size_limit : Int16 = 512
  property enable_checksums : Bool = true

  property ip_block : IPBlocks = IPBlocks.from_yaml("")

  struct IPBlocks
    include YAML::Serializable

    struct Tor
      include YAML::Serializable

      # True if you want this program to block IP addresses coming from the Tor
      # network
      property enabled : Bool = false
      # How often (in seconds) should this program update the exit nodes list
      property update_interval : Int32 = 3600
    end

    struct VPN
      include YAML::Serializable

      property enabled : Bool = false
      # How often (in seconds) should this program update the VPN IP addresses list
      property update_interval : Int32 = 86400
      # List of VPN providers
      property providers : Array(Utils::IpBlocks::VPN::Providers) = [] of Utils::IpBlocks::VPN::Providers
    end

    property tor : Tor = Tor.from_yaml("")
    property vpn : VPN = VPN.from_yaml("")
  end

  # How many files an IP address can upload to the server. Setting this to 0
  # disables rate limits in the rate limit period
  property files_per_ip : Int32 = 32
  # How often is the file limit per IP reset? (in seconds)
  property rate_limit_period : Int32 = 600

  # Delete the files after how many days?
  property delete_files_after : Int32 = 14
  # How often should the check of old files be performed? (in seconds)
  property delete_files_check : Int32 = 1800
  # The lenght of the delete key
  property delete_key_length : Int32 = 6

  # Abuse email that is going to be displayed on the website of the uploader
  property abuse_email : String = ""

  # Blocked extensions that are not allowed to be uploaded to the server
  property blocked_extensions : Array(String) = [] of String

  # Since this program detects the Host header of the client it can be used
  # with multiple domains. You can display the domains in the frontend
  # and in `/api/stats`
  property alternative_domains : Array(String) = [] of String

  def self.check_config(config : Config)
    if config.filename_length <= 0
      puts "Config: filename_length cannot be less or equal to 0"
      exit(1)
    end

    if config.s3.enabled
      # if CONFIG.generate_thumbnails
      #   puts "Config [WARNING]: Thumbnail generation disabled when using S3! This is going to be fixed on a next release!"
      #   CONFIG.generate_thumbnails = false
      # end
      {
        "Config: s3.region cannot be empty!"   => config.s3.region,
        "Config: s3.key cannot be empty!"      => config.s3.key,
        "Config: s3.secret cannot be empty!"   => config.s3.secret,
        "Config: s3.endpoint cannot be empty!" => config.s3.endpoint,
      }.each do |message, value|
        if value.empty?
          puts message
          exit(1)
        end
      end
    end

    if config.files.ends_with?('/')
      config.files = config.files.chomp('/')
    end
    if config.thumbnails.ends_with?('/')
      config.thumbnails = config.thumbnails.chomp('/')
    end
  end

  def self.load(config_file : String = "config/config.yml")
    begin
      config_yaml = File.read(config_file)
      config = Config.from_yaml(config_yaml)
    rescue File::NotFoundError
      puts "Config: Config file '#{config_file}' was not found, using the default uploader configuration"
      puts "Config, Note: You can ignore this error safely if you use environment variables to configure the uploader!"
      config = Config.from_yaml("")
    end

    # https://github.com/iv-org/invidious/blob/master/src/invidious/config.cr#L215
    # Update config from env vars (upcased and prefixed with "UPLOADER_")
    {% for ivar in Config.instance_vars %}
        {% env_id = "UPLOADER_#{ivar.id.upcase}" %}

        if ENV.has_key?({{env_id}})
            env_value = ENV.fetch({{env_id}})
            success = false

            # Use YAML converter if specified
            {% ann = ivar.annotation(::YAML::Field) %}
            {% if ann && ann[:converter] %}
                config.{{ivar.id}} = {{ann[:converter]}}.from_yaml(YAML::ParseContext.new, YAML::Nodes.parse(ENV.fetch({{env_id}})).nodes[0])
                success = true

            # Use regular YAML parser otherwise
            {% else %}
                {% ivar_types = ivar.type.union? ? ivar.type.union_types : [ivar.type] %}
                # Sort types to avoid parsing nulls and numbers as strings
                {% ivar_types = ivar_types.sort_by { |ivar_type| ivar_type == Nil ? 0 : ivar_type == Int32 ? 1 : 2 } %}
                {{ivar_types}}.each do |ivar_type|
                    if !success
                        begin
                            config.{{ivar.id}} = ivar_type.from_yaml(env_value)
                            success = true
                        rescue
                            # nop
                        end
                    end
                end
            {% end %}

            # Exit on fail
            if !success
                puts %(Config: Config.{{ivar.id}} failed to parse #{env_value} as {{ivar.type}})
                exit(1)
            end
        end

        # Warn when any config attribute is set to "CHANGE_ME!!"
        if config.{{ivar.id}} == "CHANGE_ME!!"
          puts "Config: The value of '#{ {{ivar.stringify}} }' needs to be changed!!"
          exit(1)
        end
    {% end %}

    check_config(config)
    config
  end
end
