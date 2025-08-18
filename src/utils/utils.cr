module Utils
  extend self
  Log = ::Log.for(self)

  def create_dir(path : String, reason : String? = nil) : Nil
    if !Dir.exists?(path)
      message = "creating directory '#{path}'"
      if reason
        message += " " + reason
      end
      Log.info &.emit(message)
      begin
        Dir.mkdir_p(path)
      rescue ex
        Log.fatal &.emit("failed to create directory '#{path}'", error: ex.message)
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

    Log.debug &.emit("file '#{full_filename}' was deleted using key '#{key}'")
    msg("file '#{full_filename}' deleted successfully")
  end

  # TODO: Spawn a fiber and add each file to an array to bulk delete files from
  # the database using a single SQL query.
  # In the end, all old files should be not accessible, even if they are on the
  # drive.
  def check_old_files : Nil
    Log.info &.emit("deleting old files")
    files = Database::Files.old_files

    files.each do |f|
      full_filename = f.filename + f.extension
      thumbnail = f.thumbnail

      # TODO: Check if it's able to bypass the path using a filename with a `/` in their name
      Log.debug &.emit("deleting file '#{full_filename}'")
      begin
        File.delete("#{CONFIG.files}/#{full_filename}")

        if thumbnail
          File.delete("#{CONFIG.thumbnails}/#{thumbnail}")
        end
      rescue File::NotFoundError
        Log.error &.emit("file '#{full_filename}' doesn't exist on the '#{CONFIG.files}', folder, deleting it from the database")
      rescue ex : File::AccessDeniedError
        Log.error &.emit("file '#{full_filename}' failed to be deleted due to bad permissions, deleting it from the database, error", error: ex.message)
      rescue ex
        Log.error &.emit("file '#{full_filename}' failed to be deleted, deleting it from the database, error", error: ex.message)
      ensure
        Database::Files.delete(f.filename)
      end
    end
  end

  def check_dependencies : Nil
    dependencies = ["ffmpeg"]
    dependencies.each do |dep|
      next if !CONFIG.thumbnail_generation.enabled
      if !Process.find_executable(dep)
        Log.notice &.emit("'#{dep}' was not found. Thumbnails for OpenGraph user agents will not be generated.")
        CONFIG.thumbnail_generation.enabled = false
      end
    end
  end

  # TODO: Check if there are no other possibilities to get a random filename and exit
  def generate_filename : String
    filename = Random.base58(CONFIG.filename_length)

    loop do
      file = Database::Files.select(filename)
      if !file
        return filename
      else
        Log.trace &.emit("filename collision! Generating a new filename")
        filename = Random.base58(CONFIG.filename_length)
      end
    end
  end

  # Delete socket if the server has not been previously cleaned by the server
  # (Due to unclean exits, crashes, etc.)
  def delete_socket : Nil
    if File.exists?("#{CONFIG.server.unix_socket}")
      Log.info &.emit("deleting old unix socket")
      begin
        File.delete("#{CONFIG.server.unix_socket}")
      rescue ex
        Log.fatal &.emit("#{ex.message}")
        exit(1)
      end
    end
  end
end
