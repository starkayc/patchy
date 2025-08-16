module Routes::Delete
  extend self

  def delete_file(env)
    deletion_key = env.params.query["key"]?

    if !deletion_key || deletion_key.empty?
      ee 400, "No delete key supplied"
    end

    begin
      file_deleted = OP::Delete.delete_file_by_key(deletion_key)
      if file_deleted
        msg("File '#{file_deleted}' deleted successfully using deletion key '#{deletion_key}'")
      else
        # Temporal 418 as replacement of 404, since Kemal overrides the 404
        # error code with it's own exception handler
        ee 418, "No files matches the deletion key '#{deletion_key}'"
      end
    rescue ex
      Log.error &.emit("Unknown error: #{ex.message}")
      ee 500, "Unknown error"
    end
  end
end
