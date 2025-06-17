require "awscr-s3"

module Utils::S3
  extend self

  Client = CONFIG.s3.enabled ? S3.new : nil

  class S3
    @client : Awscr::S3::Client

    def initialize
      @client = begin
        Awscr::S3::Client.new(CONFIG.s3.region, CONFIG.s3.key, CONFIG.s3.secret, endpoint: CONFIG.s3.endpoint, signer: :v4)
      rescue ex : Awscr::S3::InvalidAccessKeyId
        LOGGER.fatal "S3: Invalid access key id, please check your configuration"
        exit(1)
      rescue ex
        LOGGER.fatal "S3: Unknown error: #{ex.message}"
        exit(1)
      end
      LOGGER.info "S3: Connected to object storage at #{CONFIG.s3.endpoint}"

      check_bucket()
    end

    private def check_bucket
      if !@client.list_buckets.any? { |bucket| bucket == CONFIG.s3.bucket_name }
        begin
          @client.put_bucket(CONFIG.s3.bucket_name)
          LOGGER.info "S3: Created bucket '#{CONFIG.s3.bucket_name}'"
        rescue ex
          LOGGER.error "S3: Failed to create bucket: #{ex.message}"
        end
      end
    end

    def upload(full_filename : String, body : IO)
      uploader = Awscr::S3::FileUploader.new(@client)
      begin
        uploader.upload(CONFIG.s3.bucket_name, full_filename, body)
        LOGGER.debug "S3: File '#{full_filename}' uploaded"
      rescue ex
        LOGGER.error "S3: Failed to upload file to bucket: #{ex.message}"
      end
    end

    def delete(full_filename : String)
      begin
        @client.delete_object(CONFIG.s3.bucket_name, full_filename)
      rescue ex
        LOGGER.error "S3: Failed to delete file from bucket: #{ex.message}"
      end
    end

    def retrieve(full_filename : String)
      begin
        io = IO::Memory.new
        @client.get_object(CONFIG.s3.bucket_name, full_filename) do |file|
          IO.copy(file.body_io, io)
        end
        io.rewind
        slice = Bytes.new(io.size)
        io.read_fully(slice)
        LOGGER.debug "S3: File '#{full_filename}' retrieved"
        return slice
      rescue ex
        LOGGER.error "S3: Failed to retrieve file from bucket: #{ex.message}"
      end
    end
  end
end
