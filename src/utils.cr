module Utils
  extend self

  def create_db
    if !SQL.query_one "SELECT EXISTS (SELECT name FROM sqlite_schema WHERE type='table' AND name='#{CONFIG.db_table_name}');", as: Bool
      LOGGER.info "Creating sqlite3 database at '#{CONFIG.db}'"
      begin
        SQL.exec "CREATE TABLE IF NOT EXISTS #{CONFIG.db_table_name}
		(original_filename text, filename text, extension text, uploaded_at text, hash text, ip text, delete_key text)"
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

  def check_old_files
    LOGGER.info "Deleting old files"
    dir = Dir.new("#{CONFIG.files}")
    # Delete entries from DB
    SQL.exec "DELETE FROM #{CONFIG.db_table_name} WHERE uploaded_at < date('now', '-#{CONFIG.delete_files_after} days');"
    # Delete files
    dir.each_child do |file|
      if (Time.utc - File.info("#{CONFIG.files}/#{file}").modification_time).days >= CONFIG.delete_files_after
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

  def hash_file(file_path : String)
    File.open(file_path, "r") do |file|
      # https://crystal-lang.org/api/master/IO/Digest.html
      buffer = Bytes.new(256)
      io = IO::Digest.new(file, Digest::SHA1.new)
      io.read(buffer)
      return io.final.hexstring
    end
  end

  # TODO: Check if there are no other possibilities to get a random filename and exit
  def generate_filename
    filename = Random.base58(CONFIG.filename_length)
    loop do
      if SQL.query_one("SELECT COUNT(filename) FROM #{CONFIG.db_table_name} WHERE filename = ?", filename, as: Int32) == 0
        return filename
      else
        LOGGER.debug "Filename collision! Generating a new filename"
        filename = Random.base58(CONFIG.filename_length)
      end
    end
  end
end
