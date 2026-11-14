# Stripped down version of:
# https://github.com/athena-framework/mime/blob/f11a7f991a00b4f95a5e274bc05d10e686569570/src/magic_types_guesser.cr

module Mime
  extend self

  @[Link("magic", pkg_config: "libmagic")]
  lib LibMagic
    type MagicT = Void*

    enum Flags
      MIME_TYPE     =  0x000010 # Return the MIME type
      MIME_ENCODING = 0x0000400 # Return the MIME encoding
    end

    fun magic_open(
      flags : LibC::Int,
    ) : MagicT

    fun magic_close(
      magic : MagicT,
    ) : Void

    fun magic_file(
      magic : MagicT,
      filename : LibC::Char*,
    ) : LibC::Char*

    fun magic_buffer(
      magic : MagicT,
      buffer : Void*,
      size : LibC::SizeT,
    ) : LibC::Char*

    fun magic_load(
      magic : MagicT,
      filename : LibC::Char*,
    ) : LibC::Int

    fun magic_error(
      magic : MagicT,
    ) : LibC::Char*
  end

  private def magic(flags, &)
    unless magic = LibMagic.magic_open flags
      raise Exception.new "Failed to open libmagic."
    end

    begin
      unless LibMagic.magic_load(magic, nil).zero?
        raise Exception.new String.new LibMagic.magic_error magic
      end

      yield magic
    ensure
      LibMagic.magic_close magic
    end
  end

  def mime_type(path : String | Path) : String?
    if !File.file?(path) || !File::Info.readable?(path)
      raise Exception.new "The file '#{path}' does not exist or is not readable."
    end

    magic(flags: LibMagic::Flags::MIME_TYPE) do |magic|
      mime = LibMagic.magic_file(magic, path.to_s) || raise Exception.new String.new LibMagic.magic_error magic
      String.new mime
    end
  end

  def mime_type(data : Bytes) : String?
    magic(flags: LibMagic::Flags::MIME_TYPE) do |magic|
      mime = LibMagic.magic_buffer(magic, data, data.bytesize) || raise Exception.new String.new LibMagic.magic_error magic
      String.new mime
    end
  end

  def mime_encoding(path : String | Path) : String?
    if !File.file?(path) || !File::Info.readable?(path)
      raise Exception.new "The file '#{path}' does not exist or is not readable."
    end

    magic(flags: LibMagic::Flags::MIME_ENCODING) do |magic|
      mime = LibMagic.magic_file(magic, path.to_s) || raise Exception.new String.new LibMagic.magic_error magic
      String.new mime
    end
  end

  def mime_encoding(data : Bytes) : String?
    magic(flags: LibMagic::Flags::MIME_ENCODING) do |magic|
      mime = LibMagic.magic_buffer(magic, data, data.bytesize) || raise Exception.new String.new LibMagic.magic_error magic
      String.new mime
    end
  end
end
