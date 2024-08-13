require "../http-errors"

module Handling::Admin
  extend self

  def delete_file(env)
    if env.request.headers.try &.["X-Api-Key"]? != CONFIG.adminApiKey || nil
      error401 "Wrong API Key"
    end
    files = env.params.json["files"].as((Array(JSON::Any)))
    successfull_files = [] of String
    failed_files = [] of String
    files.each do |file|
      file = file.to_s
      begin
        fileinfo = SQL.query_one("SELECT filename, extension, thumbnail
        FROM #{CONFIG.dbTableName}
        WHERE filename = ?",
          file,
          as: {filename: String, extension: String, thumbnail: String | Nil})

        # Delete file
        File.delete("#{CONFIG.files}/#{fileinfo[:filename]}#{fileinfo[:extension]}")
        if fileinfo[:thumbnail]
          # Delete thumbnail
          File.delete("#{CONFIG.thumbnails}/#{fileinfo[:thumbnail]}")
        end
        # Delete entry from db
        SQL.exec "DELETE FROM #{CONFIG.dbTableName} WHERE filename = ?", file
        LOGGER.debug "File '#{fileinfo[:filename]}' was deleted"
        successfull_files << file
      rescue ex : DB::NoResultsError
        LOGGER.error("File '#{file}' doesn't exist or is not registered in the database: #{ex.message}")
        failed_files << file
      rescue ex
        LOGGER.error "Unknown error: #{ex.message}"
        error500 "Unknown error: #{ex.message}"
      end
    end
    json = JSON.build do |j|
      j.object do
        j.field "successfull", successfull_files.size
        j.field "failed", failed_files.size
        j.field "successfullFiles", successfull_files
        j.field "failedFiles", failed_files
      end
    end
  end
end
