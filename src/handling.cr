module Handling
  extend self

  private macro error401(message)
    env.response.content_type = "application/json"
    env.response.status_code = 401
    error_message = {"error" => {{message}}}.to_json
    return error_message
  end

  private macro error403(message)
    env.response.content_type = "application/json"
    env.response.status_code = 403
    error_message = {"error" => {{message}}}.to_json
    return error_message
  end

  private macro error404(message)
    env.response.content_type = "application/json"
    env.response.status_code = 404
    error_message = {"error" => {{message}}}.to_json
    return error_message
  end

  private macro error413(message)
    env.response.content_type = "application/json"
    env.response.status_code = 413
    error_message = {"error" => {{message}}}.to_json
    return error_message
  end

  private macro error500(message)
    env.response.content_type = "application/json"
    env.response.status_code = 500
    error_message = {"error" => {{message}}}.to_json
    return error_message
  end

  private macro msg(message)
  env.response.content_type = "application/json"
  msg = {"message" => {{message}}}.to_json
  return msg
end

  def upload(env)
    env.response.content_type = "application/json"
    # You can modify this if you want to allow files smaller than 1MiB
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
    if CONFIG.delete_key_length > 0
      delete_key = Random.base58(CONFIG.delete_key_length)
    end
    # TODO: Return the file that matches a checksum inside the database
    HTTP::FormData.parse(env.request) do |upload|
      next if upload.filename.nil? || upload.filename.to_s.empty?
      extension = File.extname("#{upload.filename}")
      if CONFIG.blocked_extensions.includes?(extension.split(".")[1])
        error401("Extension '#{extension}' is not allowed")
      end
      # TODO: Check if random string is already taken by some file (This will likely
      # never happen but it is better to design it that way)
      # filename = Random.base58(CONFIG.filename_length)
      filename = Utils.generate_filename
      if !filename.is_a?(String)
        error403("This doesn't look like a file")
      else
        file_path = ::File.join ["#{CONFIG.files}", filename + extension]
        File.open(file_path, "w") do |file|
          IO.copy(upload.body, file)
        end

        original_filename = upload.filename
        uploaded_at = Time.utc
        file_hash = Utils.hash_file(file_path)
        ip_address = env.request.remote_address.to_s.split(":").first
        SQL.exec "INSERT INTO #{CONFIG.db_table_name} VALUES (?, ?, ?, ?, ?, ?, ?)",
          original_filename, filename, extension, uploaded_at, file_hash, ip_address, delete_key
      end
    end
    if !filename.empty?
      JSON.build do |j|
        j.object do
          CONFIG.secure ? j.field "link", "https://#{env.request.headers["Host"]}/#{filename}" : j.field "link", "http://#{env.request.headers["Host"]}/#{filename}"
          j.field "linkExt", "https://#{env.request.headers["Host"]}/#{filename}#{extension}"
          j.field "id", filename
          j.field "ext", extension
          j.field "name", original_filename
          j.field "checksum", file_hash
          if CONFIG.delete_key_length > 0
            j.field "deleteKey", delete_key
            j.field "deleteLink", "https://#{env.request.headers["Host"]}/delete?key=#{delete_key}"
          end
        end
      end
    else
      error403("No file")
    end
  end

  def retrieve_file(env)
    begin
      LOGGER.debug "#{env.request.headers["X-Real-IP"]} /#{env.params.url["filename"]}"
    rescue
      LOGGER.debug "NO X-Real-IP @ /#{env.params.url["filename"]}"
    end
    begin
      filename = SQL.query_one "SELECT filename FROM #{CONFIG.db_table_name} WHERE filename = ?", env.params.url["filename"].to_s.split(".").first, as: String
      extension = SQL.query_one "SELECT extension FROM #{CONFIG.db_table_name} WHERE filename = ?", filename, as: String
      send_file env, "#{CONFIG.files}/#{filename}#{extension}"
    rescue
      LOGGER.debug "File #{filename} does not exists"
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
      LOGGER.error "#{ex.message}"
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
        error500("Unknown error: #{ex.message}")
      end
    else
      LOGGER.debug "Key '#{env.params.query["key"]}' does not exist"
      error401("Huh? This delete key doesn't exist")
    end
  end
end
