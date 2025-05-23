require "mime"

def send_file_raw(env : HTTP::Server::Context, fileinfo : UFile, file : Bytes) : Nil
  config = Kemal.config.serve_static
  mime_type = MIME.from_extension(fileinfo.extension, "application/octet-stream")
  env.response.content_type = mime_type
  env.response.headers["Accept-Ranges"] = "bytes"
  env.response.headers["X-Content-Type-Options"] = "nosniff"
  minsize = 860 # http://webmasters.stackexchange.com/questions/31750/what-is-recommended-minimum-object-size-for-gzip-performance-benefits ??
  request_headers = env.request.headers
  filesize = file.bytesize

  env.response.content_length = filesize

  env.response.write(file)

  return
end

private def multipart(file, env : HTTP::Server::Context)
  # See http://httpwg.org/specs/rfc7233.html
  fileb = file.size
  ranges = parse_ranges(env.request.headers["Range"]?, fileb)

  if ranges.empty?
    env.response.content_length = fileb
    env.response.status_code = 200 # Range not satisfiable
    IO.copy(file, env.response)
    return
  end

  if ranges.size == 1
    # Single range - send as regular partial content
    startb, endb = ranges[0]
    content_length = 1_i64 + endb - startb
    env.response.status_code = 206
    env.response.content_length = content_length
    env.response.headers["Accept-Ranges"] = "bytes"
    env.response.headers["Content-Range"] = "bytes #{startb}-#{endb}/#{fileb}"

    file.seek(startb)
    IO.copy(file, env.response, content_length)
  else
    # Multiple ranges - send as multipart/byteranges
    boundary = "kemal-#{Random::Secure.hex(16)}"
    env.response.content_type = "multipart/byteranges; boundary=#{boundary}"
    env.response.status_code = 206
    env.response.headers["Accept-Ranges"] = "bytes"

    ranges.each do |start_byte, end_byte|
      env.response.print "--#{boundary}\r\n"
      env.response.print "Content-Type: #{env.response.headers["Content-Type"]}\r\n"
      env.response.print "Content-Range: bytes #{start_byte}-#{end_byte}/#{fileb}\r\n"
      env.response.print "\r\n"

      file.seek(start_byte)
      IO.copy(file, env.response, 1_i64 + end_byte - start_byte)
      env.response.print "\r\n"
    end
    env.response.print "--#{boundary}--\r\n"
  end
end

# https://github.com/kemalcr/kemal/blob/v1.7.1/src/kemal/helpers/helpers.cr#L256
private def parse_ranges(range_header : String?, file_size : Int64) : Array({Int64, Int64})
  return [] of {Int64, Int64} unless range_header

  ranges = [] of {Int64, Int64}
  return ranges unless range_header.starts_with?("bytes=")

  range_header[6..].split(",").each do |range|
    if match = range.match /(\d{1,})-(\d{0,})/
      startb = match[1].to_i64 { 0_i64 }
      endb = match[2].to_i64 { 0_i64 }
      endb = file_size - 1 if endb == 0

      if startb < endb && endb < file_size
        ranges << {startb, endb}
      end
    end
  end

  ranges
end
