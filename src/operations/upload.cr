module OP
  extend self

  class Upload
    @uploaded_file : HTTP::FormData::Part
    @ip_addr : String
    getter fileinfo : Fileinfo = Fileinfo.new
    @ip : UIP = UIP.new

    def initialize(@uploaded_file, @ip_addr)
      @fileinfo.uploaded_at = Time.utc.to_unix
    end

    private def set_ip_information : Nil
      @fileinfo.ip = @ip_addr.to_s
      @ip.ip = @ip_addr.to_s
      @ip.date = @fileinfo.uploaded_at
    end

    private def writefile : Nil
      buffer = uninitialized UInt8[16]
      slice = buffer.to_slice
      @uploaded_file.body.read_fully(slice)

      detect_extension(slice)

      full_filename = @fileinfo.filename + @fileinfo.extension
      file_path = "#{CONFIG.files}/#{full_filename}"

      if CONFIG.s3.enabled
        body = IO::Memory.new
        IO.copy(@uploaded_file.body, body)
        # Rewind the IO first so the S3 library can calculate the correct
        # sha256 sum
        # https://github.com/taylorfinnell/awscr-s3/issues/149#issuecomment-2925707541
        body.rewind
        Utils::S3::Client.as(Utils::S3::S3).upload(full_filename, body)
      else
        File.open(file_path, "wb") do |output|
          output.write(slice)
          IO.copy(@uploaded_file.body, output)
        end
        generate_checksum(file_path)
      end
    end

    private def detect_extension(slice : Bytes) : Nil
      extension = Utils::MagicBytes.detect(slice)

      if extension
        valid_extension?(extension)
        @fileinfo.extension = extension
      else
        # Detect by filename if it wasn't detected by magic bytes
        extension = File.extname("#{@uploaded_file.filename}")
        valid_extension?(extension)
        @fileinfo.extension = extension
      end
    end

    private def valid_extension?(extension) : Nil
      if CONFIG.blocked_extensions.includes?(extension.split(".")[1]?)
        raise ExtensionNotAllowed.new(extension)
      end
    end

    private def generate_checksum(file_path : String) : Nil
      if CONFIG.enable_checksums
        @fileinfo.checksum = Utils::Hashing.hash_file(file_path)
      end
    end

    private def generate_thumbnail : Nil
      begin
        spawn { Utils::Thumbnails.generate_thumbnail(@fileinfo.filename, @fileinfo.extension) }
      rescue ex
        LOGGER.error "An error ocurred when trying to generate a thumbnail: #{ex.message}"
      end
    end

    private def insert_into_db : Nil
      begin
        Database::Files.insert(@fileinfo)
        exists = Database::IP.insert(@ip).rows_affected == 0
        Database::IP.increase_count(@ip) if exists
      rescue ex
        LOGGER.error "An error ocurred when trying to insert the data into the DB: #{ex.message}"
        raise DBError.new
      end
    end

    def process : Nil
      if filename = @uploaded_file.filename
        @fileinfo.original_filename = filename
      else
        LOGGER.debug "No file provided by the user"
        raise NoFileProvided.new
      end

      @fileinfo.filename = Utils.generate_filename

      # control_v.png and control_v.gif are filenames that are used for files
      # uploaded using Chatterino, so we change the original filename to the
      # randomly generated one.
      if ["control_v.png", "control_v.gif"].includes?(@fileinfo.original_filename)
        @fileinfo.original_filename = @fileinfo.filename
      end

      writefile()
      set_ip_information()

      if CONFIG.delete_key_length > 0
        @fileinfo.delete_key = Random.base58(CONFIG.delete_key_length)
      end

      generate_thumbnail()
      insert_into_db()

      return @fileinfo
    end
  end
end
