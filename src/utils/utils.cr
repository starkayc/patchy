module Utils
  extend self

  def create_tables
    if !Database::Files.exists?
      begin
        Database::Files.create_table
        LOGGER.info "create_tables: Created table 'files'"
      rescue ex
        LOGGER.fatal "create_tables: Failed to create 'files' table: #{ex.message}"
        exit(1)
      end
    end

    if !Database::IP.exists?
      begin
        Database::IP.create_table
        LOGGER.info "create_tables: Created table 'ips'"
      rescue ex
        LOGGER.fatal "create_tables: Failed to create 'ips' table: #{ex.message}"
        exit(1)
      end
    end
  end

  def create_files_dir
    if !Dir.exists?("#{CONFIG.files}")
      LOGGER.info "Creating files folder under '#{CONFIG.files}'"
      begin
        Dir.mkdir_p("#{CONFIG.files}")
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
          Dir.mkdir_p("#{CONFIG.thumbnails}")
        rescue ex
          LOGGER.fatal "#{ex.message}"
          exit(1)
        end
      end
    end
  end

  def create_db_dir
    if !Dir.exists?("#{CONFIG.db}")
      LOGGER.info "Creating db folder under '#{CONFIG.db}'"
      begin
        Dir.mkdir_p("#{CONFIG.db}")
      rescue ex
        LOGGER.fatal "#{ex.message}"
        exit(1)
      end
    end
  end

  def delete_file(env)
    key = env.params.query["key"]
    full_filename = fileinfo.filename + fileinfo.extension
    thumbnail = fileinfo.thumbnail

    # Delete file
    File.delete("#{CONFIG.files}/#{full_filename}")

    if fileinfo.thumbnail
      File.delete("#{CONFIG.thumbnails}/#{thumbnail}")
    end

    # Delete entry from db
    Database::Files.delete_with_key(key)

    LOGGER.debug "File '#{full_filename}' was deleted using key '#{key}'"
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
      rescue File::NotFoundError
        LOGGER.error "check_old_files: File '#{full_filename}' doesn't exist on the '#{CONFIG.files}', folder, deleting it from the database"
      rescue ex : File::AccessDeniedError
        LOGGER.error "check_old_files: File '#{full_filename}' failed to be deleted due to bad permissions, deleting it from the database, error: #{ex.message}"
      rescue ex
        LOGGER.error "check_old_files: File '#{full_filename}' failed to be deleted, deleting it from the database, error: #{ex.message}"
      ensure
        Database::Files.delete(f.filename)
      end
    end
  end

  def check_dependencies
    dependencies = ["ffmpeg"]
    dependencies.each do |dep|
      next if !CONFIG.thumbnail_generation.enabled
      if !Process.find_executable(dep)
        LOGGER.fatal("'#{dep}' was not found. Thumbnails for OpenGraph user agents will not be generated.")
        CONFIG.thumbnail_generation.enabled = false
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

  # Delete socket if the server has not been previously cleaned by the server
  # (Due to unclean exits, crashes, etc.)
  def delete_socket
    if File.exists?("#{CONFIG.server.unix_socket}")
      LOGGER.info "Deleting old unix socket"
      begin
        File.delete("#{CONFIG.server.unix_socket}")
      rescue ex
        LOGGER.fatal "#{ex.message}"
        exit(1)
      end
    end
  end
end
