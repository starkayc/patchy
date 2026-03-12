module Routes::Delete
  extend self

  def delete_file(env : HTTP::Server::Context) : Nil
    deletion_key = env.params.query["key"]?

    if !deletion_key || deletion_key.empty?
      ee 400, "No delete key supplied"
    end

    begin
      file_deleted = Operations::Deletion.delete_file(deletion_key, true)
      if file_deleted
        msg("File '#{file_deleted}' deleted successfully using deletion key '#{deletion_key}'")
      end
    rescue ex : FileNotFound
      ee 404, ex.message
    rescue ex
      Log.error &.emit("unknown error", error: ex.message)
      ee 500, "Unknown error"
    end
  end
end
