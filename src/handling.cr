require "./http-errors"

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
    file_hash = ""
    ip_address = ""
    delete_key = nil
    # TODO: Return the file that matches a checksum inside the database
    HTTP::FormData.parse(env.request) do |upload|
      next if upload.filename.nil? || upload.filename.to_s.empty?
      extension = File.extname("#{upload.filename}")
      if CONFIG.blocked_extensions.includes?(extension.split(".")[1])
        error401("Extension '#{extension}' is not allowed")
      end
      filename = Utils.generate_filename
      file_path = ::File.join ["#{CONFIG.files}", filename + extension]
      File.open(file_path, "w") do |file|
        IO.copy(upload.body, file)
      end
      original_filename = upload.filename
      uploaded_at = Time.utc
      file_hash = Utils.hash_file(file_path)
      # X-Forwarded-For if behind a reverse proxy and the header is set in the reverse
      # proxy configuration.
      ip_address = env.request.headers.try &.["X-Forwarded-For"]? ? env.request.headers.["X-Forwarded-For"] : env.request.remote_address.to_s.split(":").first
    end
    if !filename.empty?
      protocol = env.request.headers.try &.["X-Forwarded-Proto"]? ? env.request.headers["X-Forwarded-Proto"] : "http"
      host = env.request.headers.try &.["X-Forwarded-Host"]? ? env.request.headers["X-Forwarded-Host"] : env.request.headers["Host"]
      json = JSON.build do |j|
        j.object do
          j.field "link", "#{protocol}://#{host}/#{filename}"
          j.field "linkExt", "#{protocol}://#{host}/#{filename}#{extension}"
          j.field "id", filename
          j.field "ext", extension
          j.field "name", original_filename
          j.field "checksum", file_hash
          if CONFIG.delete_key_length > 0
            delete_key = Random.base58(CONFIG.delete_key_length)
            j.field "deleteKey", delete_key
            j.field "deleteLink", "#{protocol}://#{host}/delete?key=#{delete_key}"
          end
        end
      end
      begin
        # Insert SQL data just before returning the upload information
        SQL.exec "INSERT INTO #{CONFIG.db_table_name} VALUES (?, ?, ?, ?, ?, ?, ?)",
          original_filename, filename, extension, uploaded_at, file_hash, ip_address, delete_key
      rescue ex
        LOGGER.error "An error ocurred when trying to insert the data into the DB: #{ex.message}"
        error500("An error ocurred when trying to insert the data into the DB")
      end
      return json
    else
      LOGGER.debug "No file provided by the user"
      error403("No file provided")
    end
  end

  def retrieve_file(env)
    begin
      LOGGER.debug "#{env.request.headers["X-Forwarded-For"]} /#{env.params.url["filename"]}"
    rescue
      LOGGER.debug "NO X-Forwarded-For @ /#{env.params.url["filename"]}"
    end
    begin
      filename = SQL.query_one "SELECT filename FROM #{CONFIG.db_table_name} WHERE filename = ?", env.params.url["filename"].to_s.split(".").first, as: String
      original_filename = SQL.query_one "SELECT original_filename FROM #{CONFIG.db_table_name} WHERE filename = ?", env.params.url["filename"].to_s.split(".").first, as: String
      extension = SQL.query_one "SELECT extension FROM #{CONFIG.db_table_name} WHERE filename = ?", filename, as: String
      headers(env, {"Content-Disposition" => "inline; filename*=UTF-8''#{original_filename}"})
      send_file env, "#{CONFIG.files}/#{filename}#{extension}"
    rescue ex
      LOGGER.debug "File #{filename} does not exist: #{ex.message}"
      error403("File #{filename} does not exist")
    end
  end

  def stats(env)
    env.response.content_type = "application/json"
    begin
      json_data = JSON.build do |json|
        json.object do
          json.field "stats" do
            json.object do
              json.field "filesHosted", SQL.query_one "SELECT COUNT (filename) FROM #{CONFIG.db_table_name}", as: Int32
              json.field "maxUploadSize", CONFIG.size_limit
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
    if SQL.query_one "SELECT EXISTS(SELECT 1 FROM #{CONFIG.db_table_name} WHERE delete_key = ?)", env.params.query["key"], as: Bool
      begin
        file_to_delete = SQL.query_one "SELECT filename FROM #{CONFIG.db_table_name} WHERE delete_key = ?", env.params.query["key"], as: String
        file_extension = SQL.query_one "SELECT extension FROM #{CONFIG.db_table_name} WHERE delete_key = ?", env.params.query["key"], as: String
        File.delete("#{CONFIG.files}/#{file_to_delete}#{file_extension}")
        SQL.exec "DELETE FROM #{CONFIG.db_table_name} WHERE delete_key = ?", env.params.query["key"]
        LOGGER.debug "File '#{file_to_delete}' was deleted using key '#{env.params.query["key"]}'}"
        msg("File '#{file_to_delete}' deleted successfully")
      rescue ex
        LOGGER.error("Unknown error: #{ex.message}")
        error500("Unknown error")
      end
    else
      LOGGER.debug "Key '#{env.params.query["key"]}' does not exist"
      error401("Delete key '#{env.params.query["key"]}' does not exist. No files were deleted")
    end
  end
end
