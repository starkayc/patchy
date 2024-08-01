module Utils
  extend self

  def create_db
    puts "INFO: Creating sqlite3 database at '#{CONFIG.db}'"
    begin
      SQL.exec "CREATE TABLE IF NOT EXISTS files
		(original_filename text, filename text, extension text, uploaded_at text, hash text, ip text, delete_key text)"
    rescue ex
      puts "ERROR: #{ex.message}"
      exit
    end
  end

  def create_files_dir
    if !Dir.exists?("#{CONFIG.files}")
      begin
        Dir.mkdir("#{CONFIG.files}")
      rescue ex
        puts ex.message
        exit
      end
    end
  end

  def check_old_files
    puts "INFO: Deleting old files"
    dir = Dir.new("#{CONFIG.files}")
    # Delete entries from DB
    SQL.exec "DELETE FROM files WHERE uploaded_at < date('now', '-#{CONFIG.delete_files_after} days');"
    # Delete files
    dir.each_child do |file|
      if (Time.utc - File.info("#{CONFIG.files}/#{file}").modification_time).days >= CONFIG.delete_files_after
        puts "INFO: Deleting file '#{file}'"
        begin
          File.delete("#{CONFIG.files}/#{file}")
        rescue ex
          puts "ERROR: #{ex.message}"
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
end
