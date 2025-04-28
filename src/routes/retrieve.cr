module Routes::Retrieve
  extend self

  def retrieve_file(env)
    host = env.request.headers["X-Forwarded-Host"]? || env.request.headers["Host"]?
    scheme = env.request.headers["X-Forwarded-Proto"]? || "http"
    ip_addr = env.request.headers["X-Real-IP"]? || env.request.remote_address.as?(Socket::IPAddress).try &.address
    filename = env.params.url["filename"].split(".").first

    begin
      file = Database::Files.select(filename)
      if file.nil?
        ee 404, "File '#{filename}' does not exist"
      end
    rescue ex
      LOGGER.debug "Error when retrieving file '#{filename}': #{ex.message}"
      ee 500, "Error when retrieving file '#{filename}'"
    end

    env.response.headers["Content-Disposition"] = "inline; filename*=UTF-8''#{file.original_filename}"
    env.response.headers["ETag"] = "#{file.checksum}"

    CONFIG.opengraph_useragents.each do |useragent|
      env.response.content_type = "text/html"

      if env.request.headers["User-Agent"]?.try &.includes?(useragent)
        return %(<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta property="og:title" content="#{file.original_filename}">
    <meta property="og:url" content="#{scheme}://#{host}/#{file.filename}">
    #{%(<meta property="og:image" content="#{scheme}://#{host}/thumbnail/#{file.filename}.jpg">) if file.thumbnail}
  </head>
</html>)
      end
    end
    send_file env, "#{CONFIG.files}/#{file.filename}#{file.extension}"
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
