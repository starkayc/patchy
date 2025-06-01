module Routes::Views
  extend self

  def root(env)
    host = Headers.host
    scheme = Headers.scheme
    files_hosted = Database::Files.file_count

    templated "index"
  end

  def show_file(env)
    host = Headers.host
    scheme = Headers.scheme
    filename = env.params.url["filename"].split(".").first

    begin
      fileinfo = Database::Files.select(filename)
      if fileinfo.nil?
        ee 404, "File '#{filename}' does not exist"
      end
    rescue ex
      ee 500, "Error when retrieving file '#{filename}'"
    end

    mime_type = MIME.from_extension(fileinfo.extension, "application/octet-stream")

    templated "show_file"
  end

  def uploader_configs(env)
    host = Headers.host
    scheme = Headers.scheme

    templated "uploader_configs"
  end

  def admin(env)
    host = Headers.host
    scheme = Headers.scheme

    templated "admin"
  end

  def reportabuse(env)
    host = Headers.host
    scheme = Headers.scheme

    templated "reportabuse"
  end

  def login(env)
    host = Headers.host
    scheme = Headers.scheme

    templated "login"
  end
end
