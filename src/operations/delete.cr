module OP::Delete
  extend self

  def delete_file(fileinfo : UFile) : Nil
    full_filename = fileinfo.filename + fileinfo.extension
    thumbnail = fileinfo.thumbnail

    if CONFIG.s3.enable
      Utils::S3::Client.as(Utils::S3::S3).delete(full_filename)
    else
      # Delete file
      File.delete("#{CONFIG.files}/#{full_filename}")

      # Delete thumbnail if it was generated
      if fileinfo.thumbnail
        File.delete("#{CONFIG.thumbnails}/#{thumbnail}")
      end
    end
  end

  def delete_file(filename : String) : String?
    fileinfo = Database::Files.select(filename)
    if fileinfo
      full_filename = fileinfo.filename + fileinfo.extension
      begin
        delete_file(fileinfo)

        # Delete entry from db
        Database::Files.delete(fileinfo)
        LOGGER.debug "delete_file (filename): File '#{full_filename}' was deleted"
        return full_filename
      rescue ex
        LOGGER.error "delete_file (filename): Unknown error: #{ex.message}"
        raise ex
      end
    else
      raise FileNotFound.new
      return nil
    end
  end

  def delete_file_by_key(deletion_key : String) : String?
    fileinfo = Database::Files.select_with_key(deletion_key)
    if fileinfo
      full_filename = fileinfo.filename + fileinfo.extension
      begin
        delete_file(fileinfo)
        # Delete entry from db
        Database::Files.delete_with_key(deletion_key)
        LOGGER.debug "delete_file (deletion_key): File '#{full_filename}' was deleted using key '#{deletion_key}'}"
        return full_filename
      rescue ex
        LOGGER.error("delete_file (deletion_key): Unknown error: #{ex.message}")
        raise ex
      end
    else
      return nil
    end
  end
end
