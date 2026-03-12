require "yaml"

class Config
  include YAML::Serializable

  # Colorize logs
  property colorize_logs : Bool = true
  # Log level
  property log_level : Log::Severity = Log::Severity::Info

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

  property cors : Cors = Cors.from_yaml("")

  struct Cors
    include YAML::Serializable

    property enabled : Bool = false
    property paths : Array(String) = [
      "/-/file/:filename",
      "/-/thumbnail/:thumbnail",
      "/upload",
      "/-/upload",
    ]
    property access_control : AccessControl = AccessControl.from_yaml("")

    struct AccessControl
      include YAML::Serializable

      property allow_origin : String = "*"
      property allow_methods : String = "GET, HEAD, OPTIONS"
      property allow_headers : String = "Content-Type"
      property max_age : String = "3600"
    end
  end

  # Generate thumbnails for OpenGraph compatible platforms like Chatterino
  # Whatsapp, Facebook, Discord, etc.
  property thumbnail_generation : ThumbnailGeneration = ThumbnailGeneration.from_yaml("")

  struct ThumbnailGeneration
    include YAML::Serializable

    property enabled : Bool = false
    property resolution : Resolution = Resolution.from_yaml("")
    property fallback_thumbnail : CustomThumbnail = CustomThumbnail.from_yaml("")

    struct CustomThumbnail
      include YAML::Serializable

      property enabled : Bool = false
      property thumbnail_file : String = "nothumbnail.jpg"
    end

    struct Resolution
      include YAML::Serializable

      property max_height : String = "720"
      property max_width : String = "720"
    end
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
    # Type of cache to be used, defaults to LRU
    property type : Utils::Cache::Type = Utils::Cache::Type::LRU
    # The Redis URL to connect to a Redis compatible database
    property redis_url : String = ""

    # Number of files that can be cached (LRU Only)
    property max_size : Int32 = 256
    # In KiB, files bigger than this will not be cached
    property max_allowed_filesize : Int32 = 512
    property expire_time : UInt64? = nil
    # Interval to check for expired files. (LRU Only)
    property clean_interval : UInt32? = nil
  end

  property views : Views = Views.from_yaml("")

  struct Views
    include YAML::Serializable

    property index : Index = Index.from_yaml("")
    property show_file : ShowFile = ShowFile.from_yaml("")

    struct Index
      include YAML::Serializable

      property site_info : String = "Welcome to Patchy - A temporary file uploader"
      property show_title : Bool = true
      property show_file_count : Bool = true
      property show_version : Bool = true
      property navbar : Navbar = Navbar.from_yaml("")

      struct Navbar
        include YAML::Serializable

        property enabled : Bool = true
        property show_uploader_configs : Bool = true
        property show_upload_history : Bool = true
        property show_settings : Bool = true
        property show_admin : Bool = true
        property show_login : Bool = true
      end
    end

    struct ShowFile
      include YAML::Serializable

      property autoplay_video : Bool = false
      property autoplay_audio : Bool = false
    end
  end

  property admin : Admin = Admin.from_yaml("")

  struct Admin
    include YAML::Serializable

    # Enable or disable the admin API
    property enabled : Bool = false
    # The API key for admin routes. It's passed as a "X-Api-Key" header to the
    # request
    property api_key : String? = nil
  end

  # Filename length
  property filename_length : Int32 = 5
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

  # Delete the files after how many hours?
  property delete_files_after : Int32 = 168
  # How often should the check of old files be performed? (in seconds)
  property delete_files_check : Int32 = 1800
  # The lenght of the delete key
  property delete_key_length : Int32 = 6

  property analytics : Analytics = Analytics.from_yaml("")

  struct Analytics
    include YAML::Serializable

    # Cloudflare Web Analytics beacon token.
    # Leave empty to disable Cloudflare analytics.
    property cloudflare_token : String = ""
  end

  # Abuse email that is going to be displayed on the website of the uploader
  property abuse_email : String = ""

  # Blocked extensions that are not allowed to be uploaded to the server
  property blocked_extensions : Array(String) = [] of String

  # Since this program detects the Host header of the client it can be used
  # with multiple domains. You can display the domains in the frontend
  # and in `/api/stats`
  property alternative_domains : Array(String) = [] of String

  def self.check_config(config : Config) : String?
    if config.filename_length <= 0
      Log.fatal &.emit("Config: filename_length cannot be less or equal to 0")
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

  def self.load(config_file : String = "config/config.yml") : Config
    begin
      config_yaml = File.read(config_file)
      config = Config.from_yaml(config_yaml)
    rescue File::NotFoundError
      Log.notice &.emit("Config: Config file '#{config_file}' was not found, using the default uploader configuration")
      Log.notice &.emit("Config, Note: You can ignore this error safely if you use environment variables to configure the uploader!")
      config = Config.from_yaml("")
    rescue ex
      Log.fatal &.emit("Config: Failed to load config", error: ex.message)
      exit(1)
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
                Log.fatal &.emit(%(Config: Config.{{ivar.id}} failed to parse #{env_value} as {{ivar.type}}))
                exit(1)
            end
        end

        # Warn when any config attribute is set to "CHANGE_ME!!"
        if config.{{ivar.id}} == "CHANGE_ME!!"
          Log.fatal &.emit("Config: The value of '#{ {{ivar.stringify}} }' needs to be changed!!")
          exit(1)
        end
    {% end %}

    check_config(config)
    config
  end
end
