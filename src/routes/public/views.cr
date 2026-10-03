module Routes::Views
  extend self

  enum Filetype
    File  = 0
    Image = 1
    Video = 2
    Audio = 3
  end

<<<<<<< HEAD
=======
  IMAGE_EXTENSIONS = Set{".png", ".jpg", ".gif", ".webp", ".jpeg", ".bmp", ".tiff", ".jfif", ".avif", ".jxl"}
  VIDEO_EXTENSIONS = Set{".mp4", ".m4v", ".webm", ".avi", ".mov", ".ogv", ".mkv"}
  AUDIO_EXTENSIONS = Set{".flac", ".wav", ".mp3", ".acc", ".ogg", ".opus", ".m4a"}

>>>>>>> upstream/master
  def index(env : HTTP::Server::Context) : String
    locale = Headers.locale
    host = Headers.host
    scheme = Headers.scheme
    files_hosted = Database::Files.file_count

    templated "index"
  end

  def show_file(env : HTTP::Server::Context) : String?
<<<<<<< HEAD
    user_agent = Headers.user_agent

    if ["Discordbot/2.0"].any? { |ua| user_agent.includes?(ua) }
=======
    client_user_agent = Headers.user_agent

    # Sends the file instead of SHOWING the file.
    if ["Discordbot/2.0"].any? { |bot_user_agents| client_user_agent.includes?(bot_user_agents) }
>>>>>>> upstream/master
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
<<<<<<< HEAD
    rescue ex
=======
    rescue
>>>>>>> upstream/master
      return templated "show_file_error"
    end

    mime_type = MIME.from_extension(fileinfo.extension, "application/octet-stream")

<<<<<<< HEAD
=======
    filetype = if IMAGE_EXTENSIONS.includes?(fileinfo.extension)
                 Filetype::Image
               elsif VIDEO_EXTENSIONS.includes?(fileinfo.extension)
                 Filetype::Video
               elsif AUDIO_EXTENSIONS.includes?(fileinfo.extension)
                 Filetype::Audio
               else
                 Filetype::File
               end

>>>>>>> upstream/master
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
<<<<<<< HEAD
=======
    user_settings = Headers.user_settings
>>>>>>> upstream/master

    templated "settings"
  end
end
