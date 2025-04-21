module Utils
  extend self

  def create_db
    if !SQL.query_one "SELECT EXISTS (SELECT 1 FROM sqlite_schema WHERE type='table' AND name='files')
		AND EXISTS (SELECT 1 FROM sqlite_schema WHERE type='table' AND name='ips');", as: Bool
      LOGGER.info "Creating sqlite3 database at '#{CONFIG.db}'"
      begin
        SQL.exec "CREATE TABLE IF NOT EXISTS files
		(original_filename text, filename text, extension text, uploaded_at text, checksum text, ip text, delete_key text, thumbnail text)"
        SQL.exec "CREATE TABLE IF NOT EXISTS ips
		(ip text UNIQUE, count integer DEFAULT 0, date integer)"
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
    if CONFIG.thumbnails
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

  def delete_file(env)
    key = env.params.query["key"]
    file = SQL.select_with_key(key)
    full_filename = file.filename + file.extension
    thumbnail = file.thumbnail

    # Delete file
    File.delete("#{CONFIG.files}/#{full_filename}")

    if file.thumbnail
      File.delete("#{CONFIG.thumbnails}/#{thumbnail}")
    end

    # Delete entry from db
    Database::Files.delete_with_key(key)

    LOGGER.debug "File '#{full_filename}' was deleted using key '#{key}'}"
    msg("File '#{full_filename}' deleted successfully")
  end

  # TODO: Spawn a fiber and add each file to an array to bulk delete files from
  # the database using a single SQL query.
  # In the end, all old files should be not accessible, even if they are on the
  # drive.
  def check_old_files
    LOGGER.info "check_old_files: Deleting old files"
    files = Database::Files.old_files

    files.each do |f|
      full_filename = f.filename + f.extension
      thumbnail = f.thumbnail

      # TODO: Check if it's able to bypass the path using a filename with a `/` in their name
      LOGGER.debug "check_old_files: Deleting file '#{full_filename}'"
      begin
        File.delete("#{CONFIG.files}/#{full_filename}")

        if thumbnail
          File.delete("#{CONFIG.thumbnails}/#{thumbnail}")
        end

        Database::Files.delete(f.filename)
      rescue File::NotFoundError
        LOGGER.error "check_old_files: File '#{full_filename}' doesn't seem to exist on the '#{CONFIG.files}', folder, deleting it from the database"
        Database::Files.delete(f.filename)
      rescue ex : File::AccessDeniedError
        LOGGER.error "check_old_files: File '#{full_filename}' failed to be deleted due to bad permissions, deleting it from the database: #{ex.message}"
        Database::Files.delete(f.filename)
      rescue ex
        LOGGER.error "check_old_files: File '#{full_filename}' failed to be deleted, deleting it from the database: #{ex.message}"
        Database::Files.delete(f.filename)
      end
    end
  end

  def check_dependencies
    dependencies = ["ffmpeg"]
    dependencies.each do |dep|
      next if !CONFIG.generate_thumbnails
      if !Process.find_executable(dep)
        LOGGER.fatal("'#{dep}' was not found.")
        exit(1)
      end
    end
  end

  # TODO: Check if there are no other possibilities to get a random filename and exit
  def generate_filename
    filename = Random.base58(CONFIG.filename_length)

    loop do
      file = Database::Files.select(filename)
      if !file
        return filename
      else
        LOGGER.trace "Filename collision! Generating a new filename"
        filename = Random.base58(CONFIG.filename_length)
      end
    end
  end

  def generate_thumbnail(filename, extension)
    exts = [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".webp", ".heic", ".jxl", ".avif", ".crw", ".dng",
            ".mp4", ".mkv", ".webm", ".avi", ".wmv", ".flv", "m4v", ".mov", ".amv", ".3gp", ".mpg", ".mpeg", ".yuv"]

    # To prevent thumbnail generation on non image extensions
    return if exts.none? { |ext| extension.downcase.includes?(ext) }

    # Disable generation if false
    return if !CONFIG.generate_thumbnails || !CONFIG.thumbnails

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
      LOGGER.debug "Thumbnail for '#{filename + extension}' generated successfully"
      SQL.exec "UPDATE files SET thumbnail = ? WHERE filename = ?", filename + ".jpg", filename
    else
      LOGGER.debug "Failed to generate thumbnail for '#{filename + extension}'. Exit code of ffmpeg: #{process.exit_code}"
    end
  end

  # Delete socket if the server has not been previously cleaned by the server
  # (Due to unclean exits, crashes, etc.)
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

  MAGIC_BYTES = {
    # Images
    ".png"  => "89504e470d0a1a0a",
    ".heic" => "6674797068656963",
    ".jpg"  => "ffd8ff",
    ".gif"  => "474946383",
    # Videos
    ".mp4"  => "66747970",
    ".webm" => "1a45dfa3",
    ".mov"  => "6d6f6f76",
    ".wmv"  => "󠀀3026b2758e66cf11",
    ".flv"  => "󠀀464c5601",
    ".mpeg" => "000001bx",
    # Audio
    ".mp3"  => "󠀀494433",
    ".aac"  => "󠀀fff1",
    ".wav"  => "󠀀57415645666d7420",
    ".flac" => "󠀀664c614300000022",
    ".ogg"  => "󠀀4f67675300020000000000000000",
    ".wma"  => "󠀀3026b2758e66cf11a6d900aa0062ce6c",
    ".aiff" => "󠀀464f524d00",
    # Whatever
    ".7z"  => "377abcaf271c",
    ".gz"  => "1f8b",
    ".iso" => "󠀀4344303031",
    # Documents
    "pdf"  => "󠀀25504446",
    "html" => "<!DOCTYPE html>",
  }

  def detect_extension(file) : String
    file = File.open(file)
    slice = Bytes.new(16)
    hex = IO::Hexdump.new(file)
    # Reads the first 16 bytes of the file in Heap
    hex.read(slice)
    MAGIC_BYTES.each do |ext, mb|
      if slice.hexstring.includes?(mb)
        return ext
      end
    end
    ""
  end
end
