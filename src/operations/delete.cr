module Operations
  module Deletion
    extend self
    Log = ::Log.for(self)

    private def delete(full_filename : String, thumbnail : String?) : Nil
      if CONFIG.s3.enabled
        Utils::S3::Client.as(Utils::S3::S3).delete(full_filename)
      else
        # Delete file
        File.delete("#{CONFIG.files}/#{full_filename}")

        # Delete thumbnail if it was generated
        if thumbnail
          File.delete("#{CONFIG.thumbnails}/#{thumbnail}")
        end
      end
    end

    def delete_file(filename_or_key : String, is_key : Bool) : String?
      fileinfo = is_key ? Database::Files.select_with_key(filename_or_key) : Database::Files.select(filename_or_key)
      if fileinfo
        full_filename = fileinfo.filename + fileinfo.extension
        thumbnail = fileinfo.thumbnail
        begin
          self.delete(full_filename, thumbnail)
          # Delete entry from db
          Database::Files.delete(fileinfo)
          Log.debug &.emit "file '#{full_filename}' was deleted"
          return full_filename
        rescue ex
          Log.error &.emit("unknown error: #{ex.message}")
          raise ex
        end
      else
        raise FileNotFound.new
      end
    end
  end
end
