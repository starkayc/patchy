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

    process = generate_big_thumbnail(filename, extension)

    if process.exit_reason == Process::ExitReason::Normal
      Log.debug &.emit("thumbnail for '#{filename + extension}' generated successfully")
      return "#{filename}.jpg"
    else
      Log.debug &.emit("failed to generate thumbnail for '#{filename + extension}'. Exit code of ffmpeg: #{process.exit_code}")
    end
  end

  private def generate_small_thumbnail(filename : String, extension : String) : Process::Status
    process = Process.run("ffmpeg",
      [
        "-hide_banner",
        "-i",
        "#{CONFIG.files}/#{filename + extension}",
        "-movflags", "faststart",
        "-f", "mjpeg",
        "-q:v", "2",
        "-vf", "scale='min(350,iw)':'min(350,ih)':force_original_aspect_ratio=decrease, thumbnail=100",
        "-frames:v", "1",
        "-update", "1",
        "#{CONFIG.thumbnails}/#{filename}.jpg",
      ])
    process
  end

  private def generate_big_thumbnail(filename : String, extension : String) : Process::Status
    process = Process.run("ffmpeg",
      [
        "-hide_banner",
        "-i",
        "#{CONFIG.files}/#{filename + extension}",
        "-movflags", "faststart",
        "-f", "mjpeg",
        "-q:v", "2",
        "-frames:v", "1",
        "-update", "1",
        "#{CONFIG.thumbnails}/#{filename}.jpg",
      ])
    process
  end
end
