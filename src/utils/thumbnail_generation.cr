module Utils::Thumbnails
  extend self
  Log = ::Log.for(self)

  private ALLOWED_EXTENSIONS =
    Routes::Views::IMAGE_EXTENSIONS +
      Routes::Views::VIDEO_EXTENSIONS +
      Routes::Views::AUDIO_EXTENSIONS +
      Set{".heic", ".crw", ".dng", ".wmv", ".flv", ".amv", ".3gp", ".mpg", ".mpeg", ".yuv", ".ogv"}

  def generate_thumbnail(filename : String, extension : String, background_generation : Bool) : String?
    ext = extension.downcase
    is_audio = Routes::Views::AUDIO_EXTENSIONS.includes?(ext)

    if !CONFIG.thumbnail_generation.enabled ||
       ALLOWED_EXTENSIONS.none? { |allowed| ext.includes?(allowed) }
      return
    end

    Log.debug &.emit("generating thumbnail for #{filename + extension}", background_generation: background_generation)
    process = is_audio ? generate_audio_cover(filename, extension) : generate(filename, extension, CONFIG.thumbnail_generation.resolution)

    if process.success?
      Log.debug &.emit("thumbnail for '#{filename + extension}' generated successfully")
      "#{filename}.jpg"
    else
      Log.debug &.emit("failed to generate thumbnail for '#{filename + extension}'. Exit code of ffmpeg: #{process.exit_code}")
    end
  end

  private def generate_audio_cover(filename : String, extension : String) : Process::Status
    arguments = [
      "-hide_banner",
      "-i", "#{CONFIG.storage.files}/#{filename + extension}",
      "-map", "0:v:0",
      "-frames:v", "1",
      "-y",
      "#{CONFIG.storage.thumbnails}/#{filename}.jpg",
    ]
    Process.run("ffmpeg", arguments)
  end

  private def generate(filename : String, extension : String, resolution : Config::ThumbnailGeneration::Resolution) : Process::Status
    w = resolution.max_width
    h = resolution.max_height

    arguments = [
      "-hide_banner",
      "-i",
      "#{CONFIG.storage.files}/#{filename + extension}",
      "-movflags", "faststart",
      "-f", "mjpeg",
      "-q:v", "2",
      "-vf", "scale='min(#{w},iw)':'min(#{h},ih)':force_original_aspect_ratio=decrease, thumbnail=100",
      "-frames:v", "1",
      "-update", "1",
      "#{CONFIG.storage.thumbnails}/#{filename}.jpg",
    ]

    process = Process.run("ffmpeg", arguments)
    process
  end
end
