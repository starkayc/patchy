module Routes::Views
  extend self

  enum Filetype
    File = 0
    Image = 1
    Video = 2
    Audio = 3
  end

  def root(env)
    locale = Headers.locale
    host = Headers.host
    scheme = Headers.scheme
    files_hosted = Database::Files.file_count

    templated "index"
  end

  def show_file(env)
    locale = Headers.locale
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
    locale = Headers.locale
    host = Headers.host
    scheme = Headers.scheme

    templated "uploader_configs"
  end

  def upload_history(env)
    locale = Headers.locale
    host = Headers.host
    scheme = Headers.scheme

    templated "upload_history"
  end

  def admin(env)
    locale = Headers.locale
    host = Headers.host
    scheme = Headers.scheme

    templated "admin"
  end

  def reportabuse(env)
    locale = Headers.locale
    host = Headers.host
    scheme = Headers.scheme

    templated "reportabuse"
  end

  def login(env)
    locale = Headers.locale
    host = Headers.host
    scheme = Headers.scheme

    templated "login"
  end
end
