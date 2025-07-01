module Utils::MagicBytes
  extend self

  private MAGIC_BYTES = {
    # Images
    ".png"  => "89504e470d0a1a0a",
    ".heic" => "6674797068656963",
    ".jpg"  => "ffd8ff",
    ".gif"  => "474946383",
    # Videos
    ".mp4"  => "66747970",
    ".webm" => "1a45dfa3",
    ".mov"  => "6d6f6f76",
    ".wmv"  => "󠀀3026b2758e66cf11",
    ".flv"  => "󠀀464c5601",
    ".mpeg" => "000001bx",
    # Audio
    ".mp3"  => "󠀀494433",
    ".aac"  => "󠀀fff1",
    ".wav"  => "󠀀57415645666d7420",
    ".flac" => "󠀀664c614300000022",
    ".ogg"  => "󠀀4f67675300020000000000000000",
    ".wma"  => "󠀀3026b2758e66cf11a6d900aa0062ce6c",
    ".aiff" => "󠀀464f524d00",
    # Whatever
    ".7z"  => "377abcaf271c",
    ".gz"  => "1f8b",
    ".iso" => "󠀀4344303031",
    # Documents
    "pdf"  => "󠀀25504446",
    "html" => "<!DOCTYPE html>",
  }

  def detect(bytes : Bytes) : String?
    MAGIC_BYTES.each do |ext, mb|
      if bytes.hexstring.includes?(mb)
        LOGGER.trace "Utils::MagicBytes.detect: Extension is '#{ext}'"
        return ext
      end
    end
    nil
  end
end
