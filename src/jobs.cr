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

  def self.run
    # Tries to run the .enqueue method, if is not able to I will just not execute.
    check_old_files.try &.enqueue
  end
end
