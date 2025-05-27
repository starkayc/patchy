module Routes::Views
  extend self

  def root(env)
    host = Headers.host
    scheme = Headers.scheme
    files_hosted = Database::Files.file_count

    templated "index"
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

  def login(env)
    host = Headers.host
    scheme = Headers.scheme

    templated "login"
  end
end
