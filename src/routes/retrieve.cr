require "../ext/kemal_send_file_raw"

module Routes::Retrieve
  extend self

  def retrieve_file(env)
    host = Headers.host
    scheme = Headers.scheme
    filename = env.params.url["filename"].split(".").first

    begin
      fileinfo = Database::Files.select(filename)
      if fileinfo.nil?
        ee 404, "File '#{filename}' does not exist"
      end
    rescue ex
      LOGGER.debug "Error when retrieving file '#{filename}': #{ex.message}"
      ee 500, "Error when retrieving file '#{filename}'"
    end

    env.response.headers["Content-Disposition"] = "inline; filename*=UTF-8''#{fileinfo.original_filename}"
    env.response.headers["ETag"] = "#{fileinfo.checksum}"

    CONFIG.opengraph_useragents.each do |useragent|
      env.response.content_type = "text/html"

      if env.request.headers["User-Agent"]?.try &.includes?(useragent)
        return %(<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta property="og:title" content="#{fileinfo.original_filename}">
    <meta property="og:url" content="#{scheme}://#{host}/#{fileinfo.filename}">
    #{%(<meta property="og:image" content="#{scheme}://#{host}/-/thumbnail/#{fileinfo.filename}.jpg">) if fileinfo.thumbnail}
  </head>
</html>)
      end
    end

    if cached_file = Utils::Cache.select(fileinfo)
      send_file_raw env, fileinfo, cached_file
    else
      file_path = "#{CONFIG.files}/#{fileinfo.filename}#{fileinfo.extension}"
      Utils::Cache.insert(fileinfo, file_path)
      send_file env, file_path
    end
  end

  def retrieve_thumbnail(env)
    thumbnail = env.params.url["thumbnail"]?

    begin
      send_file env, "#{CONFIG.thumbnails}/#{thumbnail}"
    rescue ex
      LOGGER.debug "Thumbnail '#{thumbnail}' does not exist: #{ex.message}"
      ee 403, "Thumbnail '#{thumbnail}' does not exist"
    end
  end
end
