module Routes::Views
  extend self

  enum Filetype
    File  = 0
    Image = 1
    Video = 2
    Audio = 3
  end

  def index(env : HTTP::Server::Context) : String
    locale = Headers.locale
    host = Headers.host
    scheme = Headers.scheme
    files_hosted = Database::Files.file_count

    templated "index"
  end

  def show_file(env : HTTP::Server::Context) : String?
    user_agent = Headers.user_agent

    if ["Discordbot/2.0"].any? { |ua| user_agent.includes?(ua) }
      return Routes::Retrieve.retrieve_file(env)
    end

    locale = Headers.locale
    host = Headers.host
    scheme = Headers.scheme
    filename = env.params.url["filename"].split(".").first

    begin
      fileinfo = Database::Files.select(filename)
      if fileinfo.nil?
        return templated "show_file_not_exist"
      end
    rescue ex
      return templated "show_file_error"
    end

    mime_type = MIME.from_extension(fileinfo.extension, "application/octet-stream")

    templated "show_file"
  end

  def uploader_configs(env : HTTP::Server::Context) : String
    locale = Headers.locale
    host = Headers.host
    scheme = Headers.scheme

    templated "uploader_configs"
  end

  def upload_history(env : HTTP::Server::Context) : String
    locale = Headers.locale
    host = Headers.host
    scheme = Headers.scheme

    templated "upload_history"
  end

  def admin(env : HTTP::Server::Context) : String
    locale = Headers.locale
    host = Headers.host
    scheme = Headers.scheme

    templated "admin"
  end

  def reportabuse(env : HTTP::Server::Context) : String
    locale = Headers.locale
    host = Headers.host
    scheme = Headers.scheme

    templated "reportabuse"
  end

  def login(env : HTTP::Server::Context) : String
    locale = Headers.locale
    host = Headers.host
    scheme = Headers.scheme

    templated "login"
  end

  def settings(env : HTTP::Server::Context) : String
    locale = Headers.locale
    host = Headers.host
    scheme = Headers.scheme

    templated "settings"
  end
end
