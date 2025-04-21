module Utils::Hashing
  extend self

  def hash_file(file_path : String) : String
    Digest::SHA1.hexdigest &.file(file_path)
  end

  def hash_io(file_path : IO) : String
    Digest::SHA1.hexdigest &.update(file_path)
  end
end
