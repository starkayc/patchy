require "../http-errors"

module Handling::Admin
  extend self

  # /api/admin/delete
  def delete_file(env)
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

  # /api/admin/deleteiplimit
  def delete_ip_limit(env)
    ips = env.params.json["ips"].as((Array(JSON::Any)))
    successfull_ips = [] of String
    failed_ips = [] of String
    ips.each do |ip|
      ip = ip.to_s
      begin
        # Delete entry from db
        SQL.exec "DELETE FROM #{CONFIG.ipTableName} WHERE ip = ?", ip
        LOGGER.debug "Rate limit for '#{ip}' was deleted"
        successfull_ips << ip 
      rescue ex : DB::NoResultsError
        LOGGER.error("Rate limit for '#{ip}' doesn't exist or is not registered in the database: #{ex.message}")
        failed_ips << ip
      rescue ex
        LOGGER.error "Unknown error: #{ex.message}"
        error500 "Unknown error: #{ex.message}"
      end
    end
    json = JSON.build do |j|
      j.object do
        j.field "successfull", successfull_ips.size
        j.field "failed", failed_ips.size
        j.field "successfullUnbans", successfull_ips
        j.field "failedUnbans", failed_ips
      end
    end
  end
end
