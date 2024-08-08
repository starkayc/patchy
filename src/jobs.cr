# Pretty cool way to write background jobs! :)
module Jobs
  def self.check_old_files
    if CONFIG.delete_files_after_check_seconds <= 0
      LOGGER.info "File deletion is disabled"
      return
    end
    spawn do
      loop do
        Utils.check_old_files
        sleep CONFIG.delete_files_after_check_seconds
      end
    end
  end

  def self.kemal
    spawn do
      if !CONFIG.unix_socket.nil?
        Kemal.run do |config|
          config.server.not_nil!.bind_unix "#{CONFIG.unix_socket}"
        end
      else
        Kemal.run
      end
    end
  end

  def self.run
    check_old_files
    kemal
  end
end
