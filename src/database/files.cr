module Database::Files
  extend self

  # -------------------
  #  Insert / Delete
  # -------------------

  def insert(file : UFile) : Nil
    request = <<-SQL
      INSERT INTO files
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      ON CONFLICT DO NOTHING
    SQL

    SQL.exec(request, *file.to_tuple)
  end

  def delete(filename : String) : Nil
    request = <<-SQL
      DELETE
      FROM files
      WHERE filename = ?
    SQL

    SQL.exec(request, filename)
  end

  def delete_with_key(key : String) : Nil
    request = <<-SQL
      DELETE FROM files
      WHERE delete_key = ?
    SQL

    SQL.exec(request, key)
  end

  # -------------------
  #  Select
  # -------------------

  def select(filename : String) : UFile?
    request = <<-SQL
      SELECT *
      FROM files
      WHERE filename = ?
    SQL

    SQL.query_one?(request, filename, as: UFile)
  end

  def select_with_key(delete_key : String) : UFile?
    request = <<-SQL
      SELECT *
      FROM files
      WHERE delete_key = ?
    SQL

    SQL.query_one?(request, delete_key, as: UFile)
  end

  # -------------------
  #  Misc
  # -------------------

  def old_files : Array(UFile)
    request = <<-SQL
      SELECT *
      FROM files
      WHERE uploaded_at < strftime('%s', 'now') - #{CONFIG.delete_files_after * 3600}
    SQL

    SQL.query_all(request, as: UFile)
  end

  def file_count : Int32
    request = <<-SQL
      SELECT COUNT (filename)
      FROM files
    SQL

    SQL.query_one(request, as: Int32)
  end
end
