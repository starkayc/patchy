module Routes::Deletion
  extend self

  def delete_file(env)
    key = env.params.query["key"]?

    if !key || key.empty?
      ee 400, "No delete key supplied"
    end

    fileinfo = Database::Files.select_with_key(key)

    if fileinfo
      full_filename = fileinfo.filename + fileinfo.extension
      thumbnail = fileinfo.thumbnail

      begin
        # Delete file
        File.delete("#{CONFIG.files}/#{full_filename}")

        if fileinfo.thumbnail
          File.delete("#{CONFIG.thumbnails}/#{thumbnail}")
        end

        # Delete entry from db
        Database::Files.delete_with_key(key)

        LOGGER.debug "File '#{full_filename}' was deleted using key '#{key}'}"
        msg("File '#{full_filename}' deleted successfully")
      rescue ex
        LOGGER.error("Unknown error: #{ex.message}")
        ee 500, "Unknown error"
      end
    else
      LOGGER.debug "Key '#{env.params.query["key"]}' does not exist"
      ee 401, "Delete key '#{env.params.query["key"]}' does not exist. No files were deleted"
    end
  end
end
