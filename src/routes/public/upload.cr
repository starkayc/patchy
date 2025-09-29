module Routes::Upload
  extend self

  struct Response
    include JSON::Serializable

    property link : String
    @[JSON::Field(key: "linkExt")]
    property link_ext : String
    @[JSON::Field(key: "directLink")]
    property direct_link : String
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
      @thumbnail_link = "#{scheme}://#{host}/-/thumbnail/#{fileinfo.thumbnail}"
      @id = fileinfo.filename
      @ext = fileinfo.extension
      @name = fileinfo.original_filename
      @checksum = fileinfo.checksum
      @delete_key = fileinfo.delete_key
      @delete_link = "#{scheme}://#{host}/-/delete?key=#{fileinfo.delete_key}"
      @uploaded_at = fileinfo.uploaded_at
      @expires_at = fileinfo.uploaded_at + (CONFIG.delete_files_after * 60 * 60)
    end
  end

  def upload(env : HTTP::Server::Context) : String?
    host = Headers.host
    scheme = Headers.scheme
    ip_addr = Headers.ip_addr
    no_js = env.params.query.has_key?("nojs")
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

    fileinfo = Fileinfo.new

    HTTP::FormData.parse(env.request) do |upload|
      begin
        up = Operations::Upload.new(upload, ip_addr)
        up.process
        fileinfo = up.fileinfo
      rescue ex
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
