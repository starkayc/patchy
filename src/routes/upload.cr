module Routes::Upload
  extend self

  struct Response
    include JSON::Serializable

    property link : String
    @[JSON::Field(key: "linkExt")]
    property link_ext : String
    property id : String
    property ext : String
    property name : String
    property checksum : String?
    @[JSON::Field(key: "deleteKey")]
    property delete_key : String
    @[JSON::Field(key: "deleteLink")]
    property delete_link : String

    def initialize(file : UFile, scheme : String, host : String?)
      @link = "#{scheme}://#{host}/#{file.filename}"
      @link_ext = "#{scheme}://#{host}/#{file.filename}#{file.extension}"
      @id = file.filename
      @ext = file.extension
      @name = file.original_filename
      @checksum = file.checksum
      @delete_key = file.delete_key
      @delete_link = "#{scheme}://#{host}/delete?key=#{file.delete_key}"
    end
  end

  def upload(env)
    host = env.request.headers["X-Forwarded-Host"]? || env.request.headers["Host"]?
    scheme = env.request.headers["X-Forwarded-Proto"]? || "http"
    ip_addr = env.request.headers["X-Real-IP"]? || env.request.remote_address.as?(Socket::IPAddress).try &.address
    env.response.content_type = "application/json"

    # You can modify this if you want to allow files smaller than 1MiB.
    # This is generally a good way to check the filesize but there is a better way to do it
    # which is inspecting the file directly (If I'm not wrong).
    if CONFIG.size_limit > 0
      if !env.request.headers["Content-Length"]?.try &.to_i == nil
        if env.request.headers["Content-Length"].to_i > 1048576*CONFIG.size_limit
          ee 413, "File is too big. The maximum size allowed is #{CONFIG.size_limit}MiB"
        end
      end
    end

    file = UFile.new
    ip = UIP.new

    HTTP::FormData.parse(env.request) do |upload|
      upload_filename = upload.filename

      if upload_filename
        file.original_filename = upload_filename
      else
        LOGGER.debug "No file provided by the user"
        ee 403, "No file provided"
      end

      file.filename = Utils.generate_filename

      if file.original_filename == "control_v.png"
        file.original_filename = file.filename
      end

      file.extension = File.extname("#{upload.filename}")
      full_filename = file.filename + file.extension
      file_path = "#{CONFIG.files}/#{full_filename}"

      # Allow uploads without extension
      if !file.extension.empty?
        if CONFIG.blocked_extensions.includes?(file.extension.split(".")[1])
          ee 401, "Extension '#{file.extension}' is not allowed"
        end
      end

      File.open(file_path, "w") do |output|
        IO.copy(upload.body, output)
      end

      file.uploaded_at = Time.utc.to_unix

      if CONFIG.enable_checksums
        file.checksum = Utils::Hashing.hash_file(file_path)
      end
    end

    file.ip = ip_addr.to_s
    ip.ip = file.ip
    ip.date = file.uploaded_at

    if CONFIG.delete_key_length > 0
      file.delete_key = Random.base58(CONFIG.delete_key_length)
    end

    begin
      spawn { Utils.generate_thumbnail(file.filename, file.extension) }
    rescue ex
      LOGGER.error "An error ocurred when trying to generate a thumbnail: #{ex.message}"
    end

    begin
      Database::Files.insert(file)
      exists = Database::IP.insert(ip).rows_affected == 0
      Database::IP.increase_count(ip) if exists
    rescue ex
      LOGGER.error "An error ocurred when trying to insert the data into the DB: #{ex.message}"
      ee 500, "An error ocurred when trying to insert the data into the DB"
    end

    res = Response.new(file, scheme, host)
    res.to_json
  end
end
