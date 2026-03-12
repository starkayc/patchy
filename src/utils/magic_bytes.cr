module Utils::MagicBytes
  extend self
  Log = ::Log.for(self)

  # https://www.garykessler.net/library/file_sigs_GCK_latest.html
  private MAGIC_BYTES = {
    # Images
    ".png"  => "89504e470d0a1a0a",
    ".heic" => "6674797068656963",
    ".jpg"  => "ffd8ff",
    ".gif"  => "474946383",
    ".webp" => "57454250", # RIFF
    ".avif" => "6674797061766966",
    ".tiff" => "492049",
    ".tiff" => "49492a00",
    ".tiff" => "4d4d002a",
    ".tiff" => "4d4d002b",
    ".bmp"  => "424d",
    ".ico"  => "00000100",
    # Videos
    ".mp4"  => "66747970",
    ".webm" => "1a45dfa3",
    ".mov"  => "6d6f6f76",
    ".wmv"  => "󠀀3026b2758e66cf11",
    ".flv"  => "󠀀464c5601",
    ".mpeg" => "000001bx",
    ".avi"  => "415649204c495354", # RIFF
    # Audio
    ".mp3"  => "󠀀494433",
    ".aac"  => "󠀀fff1",
    ".wav"  => "󠀀57415645666d7420",
    ".flac" => "󠀀664c614300000022",
    ".ogg"  => "󠀀4f67675300020000000000000000",
    ".wma"  => "󠀀3026b2758e66cf11a6d900aa0062ce6c",
    ".aiff" => "󠀀464f524d00",
    ".m4a"  => "667479704d344120", # RIFF
    ".m4v"  => "667479704d345620", # RIFF
    # Whatever
    ".iso"     => "󠀀4344303031",
    ".torrent" => "64383a616e6e6f756e6365",
    # Documents
    ".pdf"  => "󠀀25504446",
    ".html" => "<!DOCTYPE html>",
    # Compressed files
    ".rar" => "526172211a0700",   # RAR v4.x
    ".rar" => "526172211a070100", # RAR v5
    ".7z"  => "377abcaf271c",
    ".gz"  => "1f8b",

  }

  def detect(bytes : Bytes) : String?
    MAGIC_BYTES.each do |ext, mb|
      if bytes.hexstring.includes?(mb)
        Log.trace &.emit("extension is '#{ext}'")
        return ext
      end
    end
    nil
  end
end
