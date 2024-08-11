require "../http-errors"
require "http/client"

module Handling
  extend self

  def upload(env)
    env.response.content_type = "application/json"
    # You can modify this if you want to allow files smaller than 1MiB.
    # This is generally a good way to check the filesize but there is a better way to do it
    # which is inspecting the file directly (If I'm not wrong).
    if CONFIG.size_limit > 0
      if env.request.headers["Content-Length"].to_i > 1048576*CONFIG.size_limit
        error413("File is too big. The maximum size allowed is #{CONFIG.size_limit}MiB")
      end
    end
    filename = ""
    extension = ""
    original_filename = ""
    uploaded_at = ""
    checksum = ""
    ip_address = ""
    delete_key = nil
    ip_address = env.request.headers.try &.["X-Forwarded-For"]? ? env.request.headers.["X-Forwarded-For"] : env.request.remote_address.to_s.split(":").first
    protocol = env.request.headers.try &.["X-Forwarded-Proto"]? ? env.request.headers["X-Forwarded-Proto"] : "http"
    host = env.request.headers.try &.["X-Forwarded-Host"]? ? env.request.headers["X-Forwarded-Host"] : env.request.headers["Host"]
    # TODO: Return the file that matches a checksum inside the database
    HTTP::FormData.parse(env.request) do |upload|
      if upload.filename.nil? || upload.filename.to_s.empty?
        LOGGER.debug "No file provided by the user"
        error403("No file provided")
      end
      # TODO: upload.body is emptied when is copied or read
      # Utils.check_duplicate(upload.dup)
      extension = File.extname("#{upload.filename}")
      if CONFIG.blockedExtensions.includes?(extension.split(".")[1])
        error401("Extension '#{extension}' is not allowed")
      end
      filename = Utils.generate_filename
      file_path = ::File.join ["#{CONFIG.files}", filename + extension]
      File.open(file_path, "w") do |output|
        IO.copy(upload.body, output)
      end
      original_filename = upload.filename
      uploaded_at = Time::Format::HTTP_DATE.format(Time.utc)
      checksum = Utils.hash_file(file_path)
    end
    # X-Forwarded-For if behind a reverse proxy and the header is set in the reverse
    # proxy configuration.
    json = JSON.build do |j|
      j.object do
        j.field "link", "#{protocol}://#{host}/#{filename}"
        j.field "linkExt", "#{protocol}://#{host}/#{filename}#{extension}"
        j.field "id", filename
        j.field "ext", extension
        j.field "name", original_filename
        j.field "checksum", checksum
        if CONFIG.deleteKeyLength > 0
          delete_key = Random.base58(CONFIG.deleteKeyLength)
          j.field "deleteKey", delete_key
          j.field "deleteLink", "#{protocol}://#{host}/delete?key=#{delete_key}"
        end
      end
    end
    begin
      spawn { Utils.generate_thumbnail(filename, extension) }
    rescue ex
      LOGGER.error "An error ocurred when trying to generate a thumbnail: #{ex.message}"
    end
    begin
      # Insert SQL data just before returning the upload information
      SQL.exec "INSERT INTO #{CONFIG.dbTableName} VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        original_filename, filename, extension, uploaded_at, checksum, ip_address, delete_key, nil
    rescue ex
      LOGGER.error "An error ocurred when trying to insert the data into the DB: #{ex.message}"
      error500("An error ocurred when trying to insert the data into the DB")
    end
    return json
  end

  # The most unoptimized and unstable feature lol
  # TODO: Support batch upload via JSON array
  def upload_url(env)
    env.response.content_type = "application/json"
    files = env.params.json["files"].as((Array(JSON::Any)))
    successfull_files = [] of NamedTuple(filename: String, extension: String, original_filename: String, checksum: String, delete_key: String | Nil)
    failed_files = [] of String
    ip_address = env.request.headers.try &.["X-Forwarded-For"]? ? env.request.headers.["X-Forwarded-For"] : env.request.remote_address.to_s.split(":").first
    protocol = env.request.headers.try &.["X-Forwarded-Proto"]? ? env.request.headers["X-Forwarded-Proto"] : "http"
    host = env.request.headers.try &.["X-Forwarded-Host"]? ? env.request.headers["X-Forwarded-Host"] : env.request.headers["Host"]
    # X-Forwarded-For if behind a reverse proxy and the header is set in the reverse
    # proxy configuration.
    if files.empty?
    end
    files.each do |url|
      url = url.to_s
      filename = Utils.generate_filename
      original_filename = ""
      extension = ""
      checksum = ""
      uploaded_at = Time::Format::HTTP_DATE.format(Time.utc)
      extension = File.extname(URI.parse(url).path)
      delete_key = nil
      file_path = ::File.join ["#{CONFIG.files}", filename + extension]
      File.open(file_path, "w") do |output|
        begin
          HTTP::Client.get(url) do |res|
            IO.copy(res.body_io, output)
          end
        rescue ex
          LOGGER.debug "Failed to download file '#{url}': #{ex.message}"
          error403("Failed to download file '#{url}'")
          failed_files << url
        end
      end
      #   successfull_files << url
      # end
      if extension.empty?
        extension = Utils.detect_extension(file_path)
        File.rename(file_path, file_path + extension)
        file_path = ::File.join ["#{CONFIG.files}", filename + extension]
      end
      # TODO: Benchmark this:
      # original_filename = URI.parse("https://ayaya.beauty/PqC").path.split("/").last
      original_filename = url.split("/").last
      checksum = Utils.hash_file(file_path)
      begin
        spawn { Utils.generate_thumbnail(filename, extension) }
      rescue ex
        LOGGER.error "An error ocurred when trying to generate a thumbnail: #{ex.message}"
      end
      begin
        # Insert SQL data just before returning the upload information
        SQL.exec("INSERT INTO #{CONFIG.dbTableName} VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
          original_filename, filename, extension, uploaded_at, checksum, ip_address, delete_key, nil)
        successfull_files << {filename:          filename,
                              original_filename: original_filename,
                              extension:         extension,
                              delete_key:        delete_key,
                              checksum:          checksum}
      rescue ex
        LOGGER.error "An error ocurred when trying to insert the data into the DB: #{ex.message}"
        error500("An error ocurred when trying to insert the data into the DB")
      end
    end
    json = JSON.build do |j|
      j.array do
        successfull_files.each do |fileinfo|
          j.object do
            j.field "link", "#{protocol}://#{host}/#{fileinfo[:filename]}"
            j.field "linkExt", "#{protocol}://#{host}/#{fileinfo[:filename]}#{fileinfo[:extension]}"
            j.field "id", fileinfo[:filename]
            j.field "ext", fileinfo[:extension]
            j.field "name", fileinfo[:original_filename]
            j.field "checksum", fileinfo[:checksum]
            if CONFIG.deleteKeyLength > 0
              delete_key = Random.base58(CONFIG.deleteKeyLength)
              j.field "deleteKey", fileinfo[:delete_key]
              j.field "deleteLink", "#{protocol}://#{host}/delete?key=#{fileinfo[:delete_key]}"
            end
          end
        end
      end
    end
    return json
  end

  def retrieve_file(env)
    protocol = env.request.headers.try &.["X-Forwarded-Proto"]? ? env.request.headers["X-Forwarded-Proto"] : "http"
    host = env.request.headers.try &.["X-Forwarded-Host"]? ? env.request.headers["X-Forwarded-Host"] : env.request.headers["Host"]
    begin
      fileinfo = SQL.query_all("SELECT filename, original_filename, uploaded_at, extension, checksum, thumbnail
      FROM #{CONFIG.dbTableName}
      WHERE filename = ?",
        env.params.url["filename"].split(".").first,
        as: {filename: String, ofilename: String, up_at: String, ext: String, checksum: String, thumbnail: String | Nil})[0]

      headers(env, {"Content-Disposition" => "inline; filename*=UTF-8''#{fileinfo[:ofilename]}"})
      headers(env, {"Last-Modified" => "#{fileinfo[:up_at]}"})
      headers(env, {"ETag" => "#{fileinfo[:checksum]}"})

      CONFIG.opengraphUseragents.each do |useragent|
        if env.request.headers.try &.["User-Agent"].includes?(useragent)
          env.response.content_type = "text/html"
          return %(
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta property="og:title" content="#{fileinfo[:ofilename]}">
    <meta property="og:url" content="#{protocol}://#{host}/#{fileinfo[:filename]}">
    #{if fileinfo[:thumbnail]
        %(<meta property="og:image" content="#{protocol}://#{host}/thumbnail/#{fileinfo[:filename]}.jpg">)
      end}
</head>
</html>
)
        end
      end
      send_file env, "#{CONFIG.files}/#{fileinfo[:filename]}#{fileinfo[:ext]}"
    rescue ex
      LOGGER.debug "File '#{env.params.url["filename"]}' does not exist: #{ex.message}"
      error403("File '#{env.params.url["filename"]}' does not exist")
    end
  end

  def retrieve_thumbnail(env)
    begin
      send_file env, "#{CONFIG.thumbnails}/#{env.params.url["thumbnail"]}"
    rescue ex
      LOGGER.debug "Thumbnail '#{env.params.url["thumbnail"]}' does not exist: #{ex.message}"
      error403("Thumbnail '#{env.params.url["thumbnail"]}' does not exist")
    end
  end

  def stats(env)
    env.response.content_type = "application/json"
    begin
      json_data = JSON.build do |json|
        json.object do
          json.field "stats" do
            json.object do
              json.field "filesHosted", SQL.query_one "SELECT COUNT (filename) FROM #{CONFIG.dbTableName}", as: Int32
              json.field "maxUploadSize", CONFIG.size_limit
              json.field "thumbnailGeneration", CONFIG.generateThumbnails
              json.field "filenameLength", CONFIG.fileameLength
            end
          end
        end
      end
    rescue ex
      LOGGER.error "Unknown error: #{ex.message}"
      error500("Unknown error")
    end
    json_data
  end

  def delete_file(env)
    if SQL.query_one "SELECT EXISTS(SELECT 1 FROM #{CONFIG.dbTableName} WHERE delete_key = ?)", env.params.query["key"], as: Bool
      begin
        fileinfo = SQL.query_all("SELECT filename, extension, thumbnail
        FROM #{CONFIG.dbTableName}
        WHERE delete_key = ?",
          env.params.query["key"],
          as: {filename: String, extension: String, thumbnail: String | Nil})[0]

        # Delete file
        File.delete("#{CONFIG.files}/#{fileinfo[:filename]}#{fileinfo[:extension]}")
        if fileinfo[:thumbnail]
          # Delete thumbnail
          File.delete("#{CONFIG.thumbnails}/#{fileinfo[:thumbnail]}")
        end
        # Delete entry from db
        SQL.exec "DELETE FROM #{CONFIG.dbTableName} WHERE delete_key = ?", env.params.query["key"]
        LOGGER.debug "File '#{fileinfo[:filename]}' was deleted using key '#{env.params.query["key"]}'}"
        msg("File '#{fileinfo[:filename]}' deleted successfully")
      rescue ex
        LOGGER.error("Unknown error: #{ex.message}")
        error500("Unknown error")
      end
    else
      LOGGER.debug "Key '#{env.params.query["key"]}' does not exist"
      error401("Delete key '#{env.params.query["key"]}' does not exist. No files were deleted")
    end
  end

  def sharex_config(env)
    protocol = env.request.headers.try &.["X-Forwarded-Proto"]? ? env.request.headers["X-Forwarded-Proto"] : "http"
    host = env.request.headers.try &.["X-Forwarded-Host"]? ? env.request.headers["X-Forwarded-Host"] : env.request.headers["Host"]
    env.response.content_type = "application/json"
    env.response.headers["Content-Disposition"] = "attachment; filename=\"#{host}.sxcu\""
    return %({
  "Version": "14.0.1",
  "DestinationType": "ImageUploader, FileUploader",
  "RequestMethod": "POST",
  "RequestURL": "#{protocol}://#{host}/upload",
  "Body": "MultipartFormData",
  "FileFormName": "file",
  "URL": "{json:link}",
  "DeletionURL": "{json:deleteLink}",
  "ErrorMessage": "{json:error}"
})
  end
end
