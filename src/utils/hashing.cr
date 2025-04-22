module Utils::Hashing
  extend self

  def hash_file(file_path : String) : String
    Digest::SHA1.hexdigest &.file(file_path)
  end

  def hash_io(file : IO) : String
    Digest::SHA1.hexdigest &.update(file)
  end
end
