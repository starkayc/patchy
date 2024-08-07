# Pretty cool way to write background jobs! :)
module Jobs
  def self.check_old_files
    if CONFIG.delete_files_after_check_seconds <= 0
      LOGGER.info "File deletion is disabled"
      return
    end
    fiber = Fiber.new do
      loop do
        Utils.check_old_files
        sleep CONFIG.delete_files_after_check_seconds
      end
    end
    return fiber
  end

  def self.kemal
    fiber = Fiber.new do
      if !CONFIG.unix_socket.nil?
        Kemal.run do |config|
          config.server.not_nil!.bind_unix "#{CONFIG.unix_socket}"
        end
      else
        Kemal.run
      end
    end
    return fiber
  end

  def self.run
    # Tries to run the .enqueue method, if is not able to I will just not execute.
    check_old_files.try &.enqueue
    kemal.try &.enqueue
  end
end
