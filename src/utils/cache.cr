module Utils::Cache
  extend self

  # TODO: Find a way to not allocate FileCache if cache is disabled
  FileCache = LRU.new

  # Based on
  # https://git.nadeko.net/Fijxu/invidious/src/commit/0dd11b2e0fe00b0a9ccc68c38a69366e77c5e6d8/src/invidious/database/videos.cr#L37
  class LRU
    @max_size : Int32
    @max_allowed_filesize : Int32
    getter lru = {} of String => {fileinfo: UFile, data: Bytes, filesize: Int64}
    @access = [] of String

    def initialize(@max_size = CONFIG.cache.max_size, @max_allowed_filesize = CONFIG.cache.max_allowed_filesize)
      if CONFIG.cache.enable
        LOGGER.info "File Cache: Using in memory LRU to store files smaller than #{(@max_allowed_filesize * 1000).humanize_bytes}"
        LOGGER.info "File Cache: Maximum amount of files the cache can hold: #{@max_size}"
        LOGGER.info "File Cache: Max bytes that the cache can hold: #{(@max_size * @max_allowed_filesize * 1000).humanize_bytes}"
      end
    end

    # TODO: Handle expire_time with a Job
    def set(fileinfo : UFile, file : File, expire_time) : Nil
      file_size = file.size

      if file_size > @max_allowed_filesize &* 1000
        LOGGER.trace("File Cache: Not caching '#{fileinfo.filename}', size too big to be cached, size: #{file_size}")
        return
      end

      slice = Bytes.new(file_size)
      file.read_fully(slice)
      self[fileinfo.filename] = {fileinfo: fileinfo, data: slice, filesize: file_size}
      LOGGER.trace("File Cache: Inserted file '#{fileinfo.filename}' to memory")
    end

    def del(fileinfo : UFile) : Nil
      self.delete(fileinfo.filename)
    end

    def get(fileinfo : UFile) : {UFile, Bytes}?
      data = self[fileinfo.filename]
      if data
        LOGGER.trace("File Cache: Retrieved file '#{fileinfo.filename}' from memory")
        return {data[:fileinfo], data[:data]}
      else
        return nil
      end
    end

    private def [](key)
      if @lru[key]?
        @access.delete(key)
        @access.push(key)
        @lru[key]
      else
        nil
      end
    end

    private def []=(key, value)
      if @lru.size >= @max_size
        lru_key = @access.shift
        @lru.delete(lru_key)
      end
      @lru[key] = value
      @access.push(key)
    end

    private def delete(key)
      if @lru[key]?
        @lru.delete(key)
        @access.delete(key)
      end
    end
  end

  def insert(fileinfo : UFile, file_path : String)
    file = File.open(file_path)
    FileCache.set(fileinfo: fileinfo, file: file, expire_time: 14400) if CONFIG.cache.enable
    file.close
  end

  def delete(fileinfo : UFile)
    FileCache.del(fileinfo)
  end

  def select(fileinfo : UFile)
    FileCache.get(fileinfo)
  end
end
