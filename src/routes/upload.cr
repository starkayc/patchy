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
    property checksum : String
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
    ip_addr = env.request.headers["X-Real-IP"]? || env.request.remote_address
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

    HTTP::FormData.parse(env.request) do |upload|
      upload_filename = upload.filename

      if upload_filename
        file.original_filename = upload_filename
      else
        LOGGER.debug "No file provided by the user"
        ee 403, "No file provided"
      end

      file.extension = File.extname("#{upload.filename}")
      file.filename = Utils.generate_filename
      full_filename = file.filename + file.extension
      file_path = "#{CONFIG.files}/#{full_filename}"

      if CONFIG.blockedExtensions.includes?(file.extension.split(".")[1])
        ee 401, "Extension '#{file.extension}' is not allowed"
      end

      File.open(file_path, "w") do |output|
        IO.copy(upload.body, output)
      end

      file.uploaded_at = Time.utc.to_unix.to_s
      file.checksum = Utils::Hashing.hash_file(file_path)
    end

    if CONFIG.deleteKeyLength > 0
      file.delete_key = Random.base58(CONFIG.deleteKeyLength)
    end

    # X-Real-IP if behind a reverse proxy and the header is set in the reverse
    # proxy configuration.
    begin
      spawn { Utils.generate_thumbnail(file.filename, file.extension) }
    rescue ex
      LOGGER.error "An error ocurred when trying to generate a thumbnail: #{ex.message}"
    end

    begin
      Database::Files.insert(file)
      # Database::IP.insert(ip_addr)
      # SQL.exec "INSERT OR IGNORE INTO ips (ip, date) VALUES (?, ?)", ip_address, Time.utc.to_unix
      # # SQL.exec "INSERT OR IGNORE INTO ips (ip) VALUES ('#{ip_address}')"
      # SQL.exec "UPDATE ips SET count = count + 1 WHERE ip = ('#{ip_address}')"
    rescue ex
      LOGGER.error "An error ocurred when trying to insert the data into the DB: #{ex.message}"
      ee 500, "An error ocurred when trying to insert the data into the DB"
    end

    res = Response.new(file, scheme, host)
    res.to_json
  end

  # The most unoptimized and unstable feature lol
  # def upload_url_bulk(env)
  #   env.response.content_type = "application/json"
  #   ip_address = Utils.ip_address(env)
  #   protocol = Utils.protocol(env)
  #   host = Utils.host(env)
  #   begin
  #     files = env.params.json["files"].as((Array(JSON::Any)))
  #   rescue ex : JSON::ParseException
  #     LOGGER.error "Body malformed: #{ex.message}"
  #     ee 400, "Body malformed: #{ex.message}"
  #   rescue ex
  #     LOGGER.error "Unknown error: #{ex.message}"
  #     ee 500, "Unknown error"
  #   end
  #   successfull_files = [] of NamedTuple(filename: String, extension: String, original_filename: String, checksum: String, delete_key: String | Nil)
  #   failed_files = [] of String
  #   # X-Real-IP if behind a reverse proxy and the header is set in the reverse
  #   # proxy configuration.
  #   files.each do |url|
  #     url = url.to_s
  #     filename = Utils.generate_filename
  #     original_filename = ""
  #     extension = ""
  #     checksum = ""
  #     uploaded_at = Time.utc
  #     extension = File.extname(URI.parse(url).path)
  #     if CONFIG.deleteKeyLength > 0
  #       delete_key = Random.base58(CONFIG.deleteKeyLength)
  #     end
  #     file_path = "#{CONFIG.files}/#{filename}#{extension}"
  #     File.open(file_path, "w") do |output|
  #       begin
  #         HTTP::Client.get(url) do |res|
  #           IO.copy(res.body_io, output)
  #         end
  #       rescue ex
  #         LOGGER.debug "Failed to download file '#{url}': #{ex.message}"
  #         ee 403, "Failed to download file '#{url}'"
  #         failed_files << url
  #       end
  #     end
  #     #   successfull_files << url
  #     # end
  #     if extension.empty?
  #       extension = Utils.detect_extension(file_path)
  #       File.rename(file_path, file_path + extension)
  #       file_path = "#{CONFIG.files}/#{filename}#{extension}"
  #     end
  #     # The second one is faster and it uses less memory
  #     # original_filename = URI.parse("https://ayaya.beauty/PqC").path.split("/").last
  #     original_filename = url.split("/").last
  #     checksum = Utils::Hashing.hash_file(file_path)
  #     begin
  #       spawn { Utils.generate_thumbnail(filename, extension) }
  #     rescue ex
  #       LOGGER.error "An error ocurred when trying to generate a thumbnail: #{ex.message}"
  #     end
  #     begin
  #       # Insert SQL data just before returning the upload information
  #       SQL.exec("INSERT INTO files VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
  #         original_filename, filename, extension, uploaded_at, checksum, ip_address, delete_key, nil)
  #       successfull_files << {filename:          filename,
  #                             original_filename: original_filename,
  #                             extension:         extension,
  #                             delete_key:        delete_key,
  #                             checksum:          checksum}
  #     rescue ex
  #       LOGGER.error "An error ocurred when trying to insert the data into the DB: #{ex.message}"
  #       ee 500, "An error ocurred when trying to insert the data into the DB"
  #     end
  #   end
  #   json = JSON.build do |j|
  #     j.array do
  #       successfull_files.each do |fileinfo|
  #         j.object do
  #           j.field "link", "#{protocol}://#{host}/#{fileinfo[:filename]}"
  #           j.field "linkExt", "#{protocol}://#{host}/#{fileinfo[:filename]}#{fileinfo[:extension]}"
  #           j.field "id", fileinfo[:filename]
  #           j.field "ext", fileinfo[:extension]
  #           j.field "name", fileinfo[:original_filename]
  #           j.field "checksum", fileinfo[:checksum]
  #           if CONFIG.deleteKeyLength > 0
  #             delete_key = Random.base58(CONFIG.deleteKeyLength)
  #             j.field "deleteKey", fileinfo[:delete_key]
  #             j.field "deleteLink", "#{protocol}://#{host}/delete?key=#{fileinfo[:delete_key]}"
  #           end
  #         end
  #       end
  #     end
  #   end
  #   json
  # end

  # def upload_url(env)
  #   env.response.content_type = "application/json"
  #   ip_address = Utils.ip_address(env)
  #   protocol = Utils.protocol(env)
  #   host = Utils.host(env)
  #   url = env.params.query["url"]
  #   successfull_files = [] of NamedTuple(filename: String, extension: String, original_filename: String, checksum: String, delete_key: String | Nil)
  #   failed_files = [] of String
  #   # X-Real-IP if behind a reverse proxy and the header is set in the reverse
  #   # proxy configuration.
  #   filename = Utils.generate_filename
  #   original_filename = ""
  #   extension = ""
  #   checksum = ""
  #   uploaded_at = Time.utc
  #   extension = File.extname(URI.parse(url).path)
  #   if CONFIG.deleteKeyLength > 0
  #     delete_key = Random.base58(CONFIG.deleteKeyLength)
  #   end
  #   file_path = "#{CONFIG.files}/#{filename}#{extension}"
  #   File.open(file_path, "w") do |output|
  #     begin
  #       # TODO: Connect timeout to prevent possible Denial of Service to the external website spamming requests
  #       # https://crystal-lang.org/api/1.13.2/HTTP/Client.html#connect_timeout
  #       HTTP::Client.get(url) do |res|
  #         IO.copy(res.body_io, output)
  #       end
  #     rescue ex
  #       LOGGER.debug "Failed to download file '#{url}': #{ex.message}"
  #       ee 403, "Failed to download file '#{url}': #{ex.message}"
  #       failed_files << url
  #     end
  #   end
  #   if extension.empty?
  #     extension = Utils.detect_extension(file_path)
  #     File.rename(file_path, file_path + extension)
  #     file_path = "#{CONFIG.files}/#{filename}#{extension}"
  #   end
  #   # The second one is faster and it uses less memory
  #   # original_filename = URI.parse("https://ayaya.beauty/PqC").path.split("/").last
  #   original_filename = url.split("/").last
  #   checksum = Utils::Hashing.hash_file(file_path)
  #   begin
  #     spawn { Utils.generate_thumbnail(filename, extension) }
  #   rescue ex
  #     LOGGER.error "An error ocurred when trying to generate a thumbnail: #{ex.message}"
  #   end
  #   begin
  #     # Insert SQL data just before returning the upload information
  #     SQL.exec("INSERT INTO files VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
  #       original_filename, filename, extension, uploaded_at, checksum, ip_address, delete_key, nil)
  #     successfull_files << {filename:          filename,
  #                           original_filename: original_filename,
  #                           extension:         extension,
  #                           delete_key:        delete_key,
  #                           checksum:          checksum}
  #   rescue ex
  #     LOGGER.error "An error ocurred when trying to insert the data into the DB: #{ex.message}"
  #     ee 500, "An error ocurred when trying to insert the data into the DB"
  #   end
  #   json = JSON.build do |j|
  #     j.array do
  #       successfull_files.each do |fileinfo|
  #         j.object do
  #           j.field "link", "#{protocol}://#{host}/#{fileinfo[:filename]}"
  #           j.field "linkExt", "#{protocol}://#{host}/#{fileinfo[:filename]}#{fileinfo[:extension]}"
  #           j.field "id", fileinfo[:filename]
  #           j.field "ext", fileinfo[:extension]
  #           j.field "name", fileinfo[:original_filename]
  #           j.field "checksum", fileinfo[:checksum]
  #           if CONFIG.deleteKeyLength > 0
  #             delete_key = Random.base58(CONFIG.deleteKeyLength)
  #             j.field "deleteKey", fileinfo[:delete_key]
  #             j.field "deleteLink", "#{protocol}://#{host}/delete?key=#{fileinfo[:delete_key]}"
  #           end
  #         end
  #       end
  #     end
  #   end
  #   json
  # end
end
