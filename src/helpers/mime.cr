# Stripped down version of:
# https://github.com/athena-framework/mime/blob/f11a7f991a00b4f95a5e274bc05d10e686569570/src/magic_types_guesser.cr

# TODO: Convert this to a module, I don't really need a struct and @magic_file
# since I will just do single operations
#
# TODO: Minify the bullshit functions
struct Mime
  def initialize(
    @magic_file : String? = nil,
  ); end

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

  def mime_type(path : String | Path) : String?
    if !File.file?(path) || !File::Info.readable?(path)
      raise Exception.new "The file '#{path}' does not exist or is not readable."
    end

    unless magic = LibMagic.magic_open LibMagic::Flags::MIME_TYPE
      raise Exception.new "Failed to open libmagic."
    end

    begin
      magic_load = if magic_file = @magic_file
                     LibMagic.magic_load magic, magic_file
                   else
                     LibMagic.magic_load magic, nil
                   end

      unless magic_load.zero?
        raise Exception.new String.new LibMagic.magic_error magic
      end

      unless mime_type = LibMagic.magic_file magic, path.to_s
        raise Exception.new String.new LibMagic.magic_error magic
      end

      String.new mime_type
    ensure
      LibMagic.magic_close magic
    end
  end

  def mime_type(data : Bytes) : String?
    unless magic = LibMagic.magic_open LibMagic::Flags::MIME_TYPE
      raise Exception.new "Failed to open libmagic."
    end

    begin
      magic_load = LibMagic.magic_load magic, nil

      unless magic_load.zero?
        raise Exception.new String.new LibMagic.magic_error magic
      end

      unless mime_type = LibMagic.magic_buffer magic, data, data.bytesize
        raise Exception.new String.new LibMagic.magic_error magic
      end

      String.new mime_type
    ensure
      LibMagic.magic_close magic
    end
  end

  def mime_encoding(path : String | Path) : String?
    if !File.file?(path) || !File::Info.readable?(path)
      raise Exception.new "The file '#{path}' does not exist or is not readable."
    end

    unless magic = LibMagic.magic_open LibMagic::Flags::MIME_ENCODING
      raise Exception.new "Failed to open libmagic."
    end

    begin
      magic_load = if magic_file = @magic_file
                     LibMagic.magic_load magic, magic_file
                   else
                     LibMagic.magic_load magic, nil
                   end

      unless magic_load.zero?
        raise Exception.new String.new LibMagic.magic_error magic
      end

      unless mime_encoding = LibMagic.magic_file magic, path.to_s
        raise Exception.new String.new LibMagic.magic_error magic
      end

      String.new mime_encoding
    ensure
      LibMagic.magic_close magic
    end
  end

  def mime_encoding(data : Bytes) : String?
    unless magic = LibMagic.magic_open LibMagic::Flags::MIME_ENCODING
      raise Exception.new "Failed to open libmagic."
    end

    begin
      magic_load = LibMagic.magic_load magic, nil

      unless magic_load.zero?
        raise Exception.new String.new LibMagic.magic_error magic
      end

      unless mime_encoding = LibMagic.magic_buffer magic, data, data.bytesize
        raise Exception.new String.new LibMagic.magic_error magic
      end

      String.new mime_encoding
    ensure
      LibMagic.magic_close magic
    end
  end
end
