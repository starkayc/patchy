require "../../ext/kemal_send_file_raw"

module Routes::Retrieve
  extend self

  # /-/file/:filename
  def retrieve_file(env : HTTP::Server::Context) : Nil
<<<<<<< HEAD
    host = Headers.host
    scheme = Headers.scheme
=======
>>>>>>> upstream/master
    if_none_match = Headers.if_none_match
    filename = env.params.url["filename"].split(".").first

    begin
      fileinfo = Database::Files.select(filename)
      if fileinfo.nil?
        ee 404, "File '#{filename}' does not exist"
      end
    rescue ex
      Log.debug &.emit("error when retrieving file '#{filename}'", error: ex.message)
      ee 500, "Error when retrieving file '#{filename}'"
    end

    # Verify the ETag sent by the client
    if if_none_match && fileinfo.checksum
      if if_none_match == fileinfo.checksum
        haltf env, status_code: 304
      end
    end

<<<<<<< HEAD
    cache_control_max_age = (fileinfo.uploaded_at + CONFIG.delete_files_after.to_i64 * 3600) - Time.utc.to_unix
=======
    cache_control_max_age = (fileinfo.uploaded_at + CONFIG.uploads.deletion.delete_files_after.to_i64 * 3600) - Time.utc.to_unix
>>>>>>> upstream/master

    # Download the HTML file contents instead of rendering it on the browser
    if fileinfo.extension != ".html"
      env.response.headers["Content-Disposition"] = "inline; filename*=UTF-8''#{fileinfo.original_filename}"
    else
      env.response.headers["Content-Disposition"] = "attachment; filename*=UTF-8''#{fileinfo.original_filename}"
    end
    env.response.headers["ETag"] = "#{fileinfo.checksum}" if fileinfo.checksum
<<<<<<< HEAD
    if !(CONFIG.delete_files_check <= 0)
=======
    if !(CONFIG.uploads.deletion.delete_files_check <= 0)
>>>>>>> upstream/master
      env.response.headers["Cache-Control"] = "public, max-age=#{cache_control_max_age}"
    else
      # Default max-age of 7 days if Patchy is configured to not delete files.
      env.response.headers["Cache-Control"] = "public, max-age=604800"
    end

<<<<<<< HEAD
    # TODO: send_file_raw and some functions
    if cached_file = Utils::Cache.select(fileinfo)
      env.response.headers["X-Patchy-Cache"] = "HIT"
      send_file_raw env, fileinfo.extension, cached_file
=======
    # TODO, store the mime values in the database when the uploaded file is being processed
    # to prevent having to calculate it again and again!
    # TODO: send_file_raw and some functions
    if cached_file = Utils::Cache.select(fileinfo)
      env.response.headers["X-Patchy-Cache"] = "HIT" if CONFIG.cache.enabled
      mime_type = Mime.mime_type(cached_file)
      mime_encoding = Mime.mime_encoding(cached_file)
      content_type = "#{mime_type}#{"; charset=" + mime_encoding if mime_encoding}"
      send_file_raw env, fileinfo.extension, cached_file, content_type
>>>>>>> upstream/master
    else
      if CONFIG.s3.enabled
        full_filename = fileinfo.filename + fileinfo.extension
        if file = Utils::S3::Client.as(Utils::S3::S3).retrieve(full_filename)
<<<<<<< HEAD
          send_file_raw env, fileinfo.extension, file
        end
      else
        file_path = "#{CONFIG.files}/#{fileinfo.filename}#{fileinfo.extension}"
        Utils::Cache.insert(fileinfo, file_path, CONFIG.cache.expire_time)
        env.response.headers["X-Patchy-Cache"] = "MISS"
        send_file env, file_path
=======
          mime_type = Mime.mime_type(file)
          mime_encoding = Mime.mime_encoding(file)
          content_type = "#{mime_type}#{"; charset=" + mime_encoding if mime_encoding}"
          send_file_raw env, fileinfo.extension, file, content_type
        end
      else
        file_path = "#{CONFIG.storage.files}/#{fileinfo.filename}#{fileinfo.extension}"
        Utils::Cache.insert(fileinfo, file_path, CONFIG.cache.expire_time)
        env.response.headers["X-Patchy-Cache"] = "MISS" if CONFIG.cache.enabled
        mime_type = Mime.mime_type(file_path)
        mime_encoding = Mime.mime_encoding(file_path)
        content_type = "#{mime_type}#{"; charset=" + mime_encoding if mime_encoding}"
        send_file env, file_path, mime_type: content_type
>>>>>>> upstream/master
      end
    end
  end

  # /-/thumbnail/:thumbnail
  def retrieve_thumbnail(env : HTTP::Server::Context) : Nil
    thumbnail = env.params.url["thumbnail"]?
    if thumbnail.nil?
      ee 404, "No thumbnail ID provided"
    end

    # The thumbnail name is the same randomly generated name of the file
    begin
      fileinfo = Database::Files.select_with_thumbnail(thumbnail)
      thumbnail = fileinfo.try &.thumbnail
      if thumbnail
<<<<<<< HEAD
        send_file env, "#{CONFIG.thumbnails}/#{thumbnail}"
      else
        thumbnail = CONFIG.thumbnail_generation.fallback_thumbnail.thumbnail_file
        baked_thumbnail = PublicAssets.get("/-/assets/img/#{thumbnail}")
=======
        send_file env, "#{CONFIG.storage.thumbnails}/#{thumbnail}"
      else
        thumbnail = CONFIG.thumbnail_generation.fallback_thumbnail.thumbnail_file
        baked_thumbnail = BakedFiles::PublicAssets.get("/-/assets/img/#{thumbnail}")
>>>>>>> upstream/master
        mime_type = MIME.from_filename(thumbnail, "application/octet-stream")
        send_file env, baked_thumbnail.to_slice, mime_type
      end
    rescue ex
      Log.debug &.emit("thumbnail '#{thumbnail}' does not exist", error: ex.message)
      ee 404, "Thumbnail '#{thumbnail}' does not exist"
    end
  end
end
