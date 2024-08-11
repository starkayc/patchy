module Utils
  extend self

  def create_db
    if !SQL.query_one "SELECT EXISTS (SELECT name FROM sqlite_schema WHERE type='table' AND name='#{CONFIG.dbTableName}');", as: Bool
      LOGGER.info "Creating sqlite3 database at '#{CONFIG.db}'"
      begin
        SQL.exec "CREATE TABLE IF NOT EXISTS #{CONFIG.dbTableName}
		(original_filename text, filename text, extension text, uploaded_at text, checksum text, ip text, delete_key text, thumbnail text)"
      rescue ex
        LOGGER.fatal "#{ex.message}"
        exit(1)
      end
    end
  end

  def create_files_dir
    if !Dir.exists?("#{CONFIG.files}")
      LOGGER.info "Creating files folder under '#{CONFIG.files}'"
      begin
        Dir.mkdir("#{CONFIG.files}")
      rescue ex
        LOGGER.fatal "#{ex.message}"
        exit(1)
      end
    end
  end

  def create_thumbnails_dir
    if !CONFIG.thumbnails
      if !Dir.exists?("#{CONFIG.thumbnails}")
        LOGGER.info "Creating thumbnails folder under '#{CONFIG.thumbnails}'"
        begin
          Dir.mkdir("#{CONFIG.thumbnails}")
        rescue ex
          LOGGER.fatal "#{ex.message}"
          exit(1)
        end
      end
    end
  end

  def check_old_files
    LOGGER.info "Deleting old files"
    dir = Dir.new("#{CONFIG.files}")
    # Delete entries from DB
    SQL.exec "DELETE FROM #{CONFIG.dbTableName} WHERE uploaded_at < date('now', '-#{CONFIG.deleteFilesAfter} days');"
    # Delete files
    dir.each_child do |file|
      if (Time.utc - File.info("#{CONFIG.files}/#{file}").modification_time).days >= CONFIG.deleteFilesAfter
        LOGGER.debug "Deleting file '#{file}'"
        begin
          File.delete("#{CONFIG.files}/#{file}")
        rescue ex
          LOGGER.error "#{ex.message}"
        end
      end
    end
    # Close directory to prevent `Too many open files (File::Error)` error.
    # This is because the directory class is still saved on memory for some reason.
    dir.close
  end

  def check_dependencies
    dependencies = ["ffmpeg"]
    dependencies.each do |dep|
      next if !CONFIG.generateThumbnails
      if !Process.find_executable(dep)
        LOGGER.fatal("'#{dep}' was not found")
        exit(1)
      end
    end
  end

  # TODO:
  # def check_duplicate(upload)
  #   file_checksum = SQL.query_all("SELECT checksum FROM #{CONFIG.dbTableName} WHERE original_filename = ?", upload.filename, as:String).try &.[0]?
  #   if file_checksum.nil?
  #     return
  #   else
  #     uploaded_file_checksum = hash_io(upload.body)
  #     pp file_checksum
  #     pp uploaded_file_checksum
  #     if file_checksum == uploaded_file_checksum
  #       puts "Dupl"
  #     end
  #   end
  # end

  def hash_file(file_path : String)
    Digest::SHA1.hexdigest &.file(file_path)
  end

  def hash_io(file_path : IO)
    Digest::SHA1.hexdigest &.update(file_path)
  end

  # TODO: Check if there are no other possibilities to get a random filename and exit
  def generate_filename
    filename = Random.base58(CONFIG.fileameLength)
    loop do
      if SQL.query_one("SELECT COUNT(filename) FROM #{CONFIG.dbTableName} WHERE filename = ?", filename, as: Int32) == 0
        return filename
      else
        LOGGER.debug "Filename collision! Generating a new filename"
        filename = Random.base58(CONFIG.fileameLength)
      end
    end
  end

  def generate_thumbnail(filename, extension)
    # Disable generation if false
    return if !CONFIG.generateThumbnails
    LOGGER.debug "Generating thumbnail for #{filename + extension} in background"
    process = Process.run("ffmpeg",
      [
        "-hide_banner",
        "-i",
        "#{CONFIG.files}/#{filename + extension}",
        "-movflags", "faststart",
        "-f", "mjpeg",
        "-q:v", "2",
        "-vf", "scale='min(350,iw)':'min(350,ih)':force_original_aspect_ratio=decrease, thumbnail=100",
        "-frames:v", "1",
        "-update", "1",
        "#{CONFIG.thumbnails}/#{filename}.jpg",
      ])
    if process.normal_exit?
      LOGGER.debug "Thumbnail for #{filename + extension} generated successfully"
      SQL.exec "UPDATE #{CONFIG.dbTableName} SET thumbnail = ? WHERE filename = ?", filename + ".jpg", filename
    else
    end
  end

  # Delete socket if the server has not been previously cleaned by the server (Due to unclean exits, crashes, etc.)
  def delete_socket
    if File.exists?("#{CONFIG.unix_socket}")
      LOGGER.info "Deleting old unix socket"
      begin
        File.delete("#{CONFIG.unix_socket}")
      rescue ex
        LOGGER.fatal "#{ex.message}"
        exit(1)
      end
    end
  end

  def delete_file(env)
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
  end

  def detect_extension(file) : String
    magic_bytes = {
      ".png"  => "89504e470d0a1a0a",
      ".jpg"  => "ffd8ff",
      ".webm" => "1a45dfa3",
      ".mp4"  => "66747970",
      ".gif"  => "474946383",
      ".7z"   => "377abcaf271c",
      ".gz"   => "1f8b",
    }
    file = File.open(file)
    slice = Bytes.new(8)
    hex = IO::Hexdump.new(file)
    hex.read(slice)
    magic_bytes.each do |ext, mb|
      if slice.hexstring.includes?(mb)
        return ext
      end
    end
    ""
  end

  def retrieve_tor_exit_nodes
    LOGGER.debug "Retrieving Tor exit nodes list"
    resp = HTTP::Client.get(CONFIG.torExitNodesUrl) do |res|
      if res.success? && res.status_code == 200
        begin
        File.open(CONFIG.torExitNodesFile, "w") do |output|
          IO.copy(res.body_io, output)
        end
      rescue ex
        LOGGER.error "Failed to write to file: #{ex.message}"
      end
      else
        LOGGER.error "Failed to retrieve exit nodes list. Status Code: #{res.status_code}"
      end
    end
  end

  def load_tor_exit_nodes
    exit_nodes = File.read_lines(CONFIG.torExitNodesFile)
  end
end
