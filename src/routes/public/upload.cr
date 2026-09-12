module Routes::Upload
  extend self

  struct Response
    include JSON::Serializable

    property link : String
    @[JSON::Field(key: "linkExt")]
    property link_ext : String
    @[JSON::Field(key: "directLink")]
    property direct_link : String
    @[JSON::Field(key: "directLinkExt")]
    property direct_link_ext : String
    @[JSON::Field(key: "thumbnailLink")]
    property thumbnail_link : String?
    property id : String
    property ext : String
    property name : String
    property checksum : String?
    @[JSON::Field(key: "deleteKey")]
    property delete_key : String
    @[JSON::Field(key: "deleteLink")]
    property delete_link : String
    @[JSON::Field(key: "uploadedAt")]
    property uploaded_at : Int64
    @[JSON::Field(key: "expiresAt")]
    property expires_at : Int64

    def initialize(fileinfo : Fileinfo, scheme : String, host : String?)
      @link = "#{scheme}://#{host}/#{fileinfo.filename}"
      @link_ext = "#{scheme}://#{host}/#{fileinfo.filename}#{fileinfo.extension}"
      @direct_link = "#{scheme}://#{host}/-/file/#{fileinfo.filename}"
      @direct_link_ext = "#{scheme}://#{host}/-/file/#{fileinfo.filename}#{fileinfo.extension}"
<<<<<<< HEAD
      @thumbnail_link = fileinfo.thumbnail ? "#{scheme}://#{host}/-/thumbnail/#{fileinfo.thumbnail}" : nil
=======
      @thumbnail_link = "#{scheme}://#{host}/-/thumbnail/#{fileinfo.thumbnail}"
>>>>>>> upstream/master
      @id = fileinfo.filename
      @ext = fileinfo.extension
      @name = fileinfo.original_filename
      @checksum = fileinfo.checksum
      @delete_key = fileinfo.delete_key
      @delete_link = "#{scheme}://#{host}/-/delete?key=#{fileinfo.delete_key}"
      @uploaded_at = fileinfo.uploaded_at
<<<<<<< HEAD
      @expires_at = fileinfo.uploaded_at + (CONFIG.delete_files_after.to_i64 * 3600)
=======
      @expires_at = fileinfo.uploaded_at + (CONFIG.uploads.deletion.delete_files_after.to_i64 * 3600)
>>>>>>> upstream/master
    end
  end

  def upload(env : HTTP::Server::Context) : String?
    host = Headers.host
    scheme = Headers.scheme
    ip_addr = Headers.ip_addr
<<<<<<< HEAD
=======
    user_settings = Headers.user_settings
>>>>>>> upstream/master
    no_js = env.params.query.has_key?("nojs")
    env.response.content_type = "application/json"

    # You can modify this if you want to allow files smaller than 1MiB.
    # This is generally a good way to check the filesize but there is a better way to do it
    # which is inspecting the file directly (If I'm not wrong).
<<<<<<< HEAD
    if CONFIG.size_limit > 0
      if !env.request.headers["Content-Length"]?.try &.to_i == nil
        if env.request.headers["Content-Length"].to_i > 1048576*CONFIG.size_limit
          ee 413, "File is too big. The maximum size allowed is #{CONFIG.size_limit}MiB"
=======
    if CONFIG.uploads.size_limit > 0
      if content_length = env.request.headers["Content-Length"]?.try &.to_u64
        if content_length > 1048576_u64*CONFIG.uploads.size_limit
          ee 413, "File is too big. The maximum size allowed is #{CONFIG.uploads.size_limit}MiB"
>>>>>>> upstream/master
        end
      end
    end

    fileinfo = Fileinfo.new

    HTTP::FormData.parse(env.request) do |upload|
      begin
<<<<<<< HEAD
        up = Operations::Upload.new(upload, ip_addr)
        up.process
        fileinfo = up.fileinfo
      rescue ex
=======
        up = Operations::Upload.new(upload, ip_addr, user_settings)
        up.process
        fileinfo = up.fileinfo
        if CONFIG.thumbnail_generation.background_generation
          spawn do
            begin
              thumbnail_filename = Utils::Thumbnails.generate_thumbnail(fileinfo.filename, fileinfo.extension, true)
              if thumbnail_filename
                Database::Files.update_thumbnail(thumbnail_filename, fileinfo.filename)
              end
            rescue ex
              Log.error &.emit("an error ocurred when trying to generate a thumbnail in the background", error: ex.message)
            end
          end
        end
      rescue ex
        Log.error &.emit("failed to process upload", error: ex.message)
>>>>>>> upstream/master
        ee 403, "Failed to process upload"
      end
    end

    # Redirect to uploaded file if it's a browser
    if no_js
      return env.redirect "/#{fileinfo.filename}"
    end

    res = Response.new(fileinfo, scheme, host)
    res.to_json
  end
end
