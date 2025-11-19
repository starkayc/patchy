module Utils::Thumbnails
  extend self
  Log = ::Log.for(self)

  private ALLOWED_EXTENSIONS =
    {".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".webp", ".heic", ".jxl", ".avif", ".crw", ".dng",
     ".mp4", ".mkv", ".webm", ".avi", ".wmv", ".flv", "m4v", ".mov", ".amv", ".3gp", ".mpg", ".mpeg", ".yuv"}

  def generate_thumbnail(filename : String, extension : String) : String?
    return unless CONFIG.thumbnail_generation.enabled &&
                  !ALLOWED_EXTENSIONS.none? { |ext| extension.downcase.includes?(ext) }
    Log.debug &.emit("generating thumbnail for #{filename + extension} in background")

    process = generate(filename, extension, CONFIG.thumbnail_generation.resolution)

    if process.exit_reason == Process::ExitReason::Normal
      Log.debug &.emit("thumbnail for '#{filename + extension}' generated successfully")
      return "#{filename}.jpg"
    else
      Log.debug &.emit("failed to generate thumbnail for '#{filename + extension}'. Exit code of ffmpeg: #{process.exit_code}")
    end
  end

  private def generate(filename : String, extension : String, resolution : Config::ThumbnailGeneration::Resolution) : Process::Status
    w = resolution.max_width
    h = resolution.max_height

    arguments = [
      "-hide_banner",
      "-i",
      "#{CONFIG.files}/#{filename + extension}",
      "-movflags", "faststart",
      "-f", "mjpeg",
      "-q:v", "2",
      "-vf", "scale='min(#{w},iw)':'min(#{h},ih)':force_original_aspect_ratio=decrease, thumbnail=100",
      "-frames:v", "1",
      "-update", "1",
      "#{CONFIG.thumbnails}/#{filename}.jpg",
    ]

    process = Process.run("ffmpeg", arguments)
    process
  end
end
