require "../ext/kemal_send_file_raw"

module Routes::Retrieve
  extend self

  def retrieve_file(env : HTTP::Server::Context) : Nil
    host = Headers.host
    scheme = Headers.scheme
    filename = env.params.url["filename"].split(".").first

    begin
      fileinfo = Database::Files.select(filename)
      if fileinfo.nil?
        ee 404, "File '#{filename}' does not exist"
      end
    rescue ex
      Log.debug &.emit "Error when retrieving file '#{filename}': #{ex.message}"
      ee 500, "Error when retrieving file '#{filename}'"
    end

    # Download the HTML file contents instead of rendering it on the browser
    if fileinfo.extension != ".html"
      env.response.headers["Content-Disposition"] = "inline; filename*=UTF-8''#{fileinfo.original_filename}"
    else
      env.response.headers["Content-Disposition"] = "attachment; filename*=UTF-8''#{fileinfo.original_filename}"
    end
    env.response.headers["ETag"] = "#{fileinfo.checksum}" if fileinfo.checksum
    env.response.headers["Expires"] = Time::Format::HTTP_DATE.format(Time.unix(fileinfo.uploaded_at + CONFIG.delete_files_after * 3600))

    # TODO: send_file_raw and some functions
    if cached_file = Utils::Cache.select(fileinfo)
      send_file_raw env, fileinfo, cached_file
    else
      if CONFIG.s3.enabled
        full_filename = fileinfo.filename + fileinfo.extension
        if file = Utils::S3::Client.as(Utils::S3::S3).retrieve(full_filename)
          send_file_raw env, fileinfo, file
        end
      else
        file_path = "#{CONFIG.files}/#{fileinfo.filename}#{fileinfo.extension}"
        Utils::Cache.insert(fileinfo, file_path)
        send_file env, file_path
      end
    end
  end

  def retrieve_thumbnail(env : HTTP::Server::Context) : Nil
    thumbnail = env.params.url["thumbnail"]?

    begin
      send_file env, "#{CONFIG.thumbnails}/#{thumbnail}"
    rescue ex
      Log.debug &.emit "Thumbnail '#{thumbnail}' does not exist: #{ex.message}"
      ee 403, "Thumbnail '#{thumbnail}' does not exist"
    end
  end
end
