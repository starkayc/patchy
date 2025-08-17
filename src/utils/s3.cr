require "awscr-s3"

module Utils::S3
  extend self
  Log = ::Log.for(self)

  Client = CONFIG.s3.enabled ? S3.new : nil

  class S3
    @client : Awscr::S3::Client

    def initialize
      @client = begin
        Awscr::S3::Client.new(CONFIG.s3.region, CONFIG.s3.key, CONFIG.s3.secret, endpoint: CONFIG.s3.endpoint, signer: :v4)
      rescue ex : Awscr::S3::InvalidAccessKeyId
        Log.fatal &.emit("invalid access key id, please check your configuration")
        exit(1)
      rescue ex
        Log.fatal &.emit("unknown error", error: ex.message)
        exit(1)
      end
      Log.info &.emit("connected to object storage at #{CONFIG.s3.endpoint}")

      check_bucket()
    end

    private def check_bucket : Nil
      if !@client.list_buckets.any? { |bucket| bucket == CONFIG.s3.bucket_name }
        begin
          @client.put_bucket(CONFIG.s3.bucket_name)
          Log.info &.emit("created bucket '#{CONFIG.s3.bucket_name}'")
        rescue ex
          Log.error &.emit("failed to create bucket", error: ex.message)
        end
      end
    end

    def upload(full_filename : String, body : IO) : Nil
      uploader = Awscr::S3::FileUploader.new(@client)
      begin
        uploader.upload(CONFIG.s3.bucket_name, full_filename, body)
        Log.debug &.emit("file '#{full_filename}' uploaded")
      rescue ex
        Log.error &.emit("failed to upload file to bucket", error: ex.message)
      end
    end

    def delete(full_filename : String) : Bool?
      begin
        @client.delete_object(CONFIG.s3.bucket_name, full_filename)
      rescue ex
        Log.error &.emit("failed to delete file from bucket", error: ex.message)
      end
    end

    def retrieve(full_filename : String) : Slice(UInt8)?
      begin
        io = IO::Memory.new
        @client.get_object(CONFIG.s3.bucket_name, full_filename) do |file|
          IO.copy(file.body_io, io)
        end
        io.rewind
        slice = Bytes.new(io.size)
        io.read_fully(slice)
        Log.debug &.emit("file '#{full_filename}' retrieved")
        return slice
      rescue ex
        Log.error &.emit("failed to retrieve file from bucket", error: ex.message)
      end
    end
  end
end
