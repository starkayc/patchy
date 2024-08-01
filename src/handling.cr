module Handling
  extend self

  def upload(env)
    filename = ""
    extension = ""
    original_filename = ""
    uploaded_at = ""
    file_hash = ""
    ip_address = ""
    delete_key = Random.base58(CONFIG.delete_key_lenght)
    # TODO: Return the file that matches a checksum inside the database
    HTTP::FormData.parse(env.request) do |upload|
      next if upload.filename.nil? || upload.filename.to_s.empty?
      extension = File.extname("#{upload.filename}")
      filename = Random.base58(CONFIG.filename_lenght)
      if !filename.is_a?(String)
        return "This doesn't look like a file"
      else
        file_path = ::File.join ["#{CONFIG.files}", filename + extension]
        File.open(file_path, "w") do |file|
          IO.copy(upload.body, file)
        end

        original_filename = upload.filename
        uploaded_at = Time.utc
        file_hash = Utils.hash_file(file_path)
        ip_address = env.request.not_nil!.remote_address.to_s.split(":").first
        SQL.exec "INSERT INTO FILES VALUES (?, ?, ?, ?, ?, ?, ?)",
          original_filename, filename, extension, uploaded_at, file_hash, ip_address, delete_key
      end
    end
    env.response.content_type = "application/json"
    if !filename.empty?
      JSON.build do |j|
        j.object do
          j.field "link", "https://#{env.request.headers["Host"]}/#{filename + extension}"
          j.field "id", filename
          j.field "ext", extension
          j.field "name", original_filename
          j.field "checksum", file_hash
          j.field "deleteKey", delete_key
          j.field "deleteLink", "https://#{env.request.headers["Host"]}/delete?key=#{delete_key}"
        end
      end
    else
      env.response.content_type = "application/json"
      env.response.status_code = 403
      error_message = {"error" => "No file"}.to_json
      error_message
    end
  end

  def retrieve_file(env)
    begin
      if !File.extname(env.params.url["filename"]).empty?
        send_file env, "#{CONFIG.files}/#{env.params.url["filename"]}"
        # next
      end
      dir = Dir.new("#{CONFIG.files}")
      dir.each do |filename|
        if filename.starts_with?("#{env.params.url["filename"]}")
          send_file env, "#{CONFIG.files}/#{env.params.url["filename"]}" + File.extname(filename)
        end
      end
      raise ""
    rescue
      env.response.content_type = "text/plain"
      env.response.status_code = 403
      return "File does not exist"
    end
  end

  def stats(env)
    begin
      dir = Dir.new("#{CONFIG.files}")
    rescue
      env.response.content_type = "text/plain"
      env.response.status_code = 403
      return "Unknown error"
    end

    json_data = JSON.build do |json|
      json.object do
        json.field "stats" do
          json.object do
            begin
              json.field "filesHosted", dir.children.size
            rescue
              json.field "filesHosted", 0
            end
          end
        end
      end
    end
    dir.close
    env.response.content_type = "application/json"
    json_data
  end

  def delete_file(env)
    if SQL.query_one "SELECT EXISTS(SELECT 1 FROM files WHERE delete_key = ?)", env.params.query["key"], as: Bool
      begin
        file_to_delete = SQL.query_one "SELECT filename FROM files WHERE delete_key = ?", env.params.query["key"], as: String
        file_extension = SQL.query_one "SELECT extension FROM files WHERE delete_key = ?", env.params.query["key"], as: String
        File.delete("#{CONFIG.files}/#{file_to_delete}#{file_extension}")
        SQL.exec "DELETE FROM files WHERE delete_key = ?", env.params.query["key"]
        env.response.content_type = "application/json"
        error_message = {"message" => "File deleted successfully"}.to_json
        error_message
      rescue
        env.response.content_type = "application/json"
        env.response.status_code = 403
      end
    else
      env.response.content_type = "application/json"
      env.response.status_code = 403
      error_message = {"error" => "Huh? This delete key doesn't exist"}.to_json
      error_message
    end
  end
end
