module Database::Files
  extend self

  # -------------------
  #  Database checking
  # -------------------

  def exists? : Bool?
    request = <<-SQL
      SELECT EXISTS
      (
      SELECT 1 FROM
      sqlite_schema
      WHERE type='table'
      AND name='files'
      )
    SQL

    SQL.query_one(request, as: Bool?)
  end

  def create_table : Nil
    request = <<-SQL
      CREATE TABLE
      IF NOT EXISTS files
      (
      original_filename text not null,
      filename text not null,
      extension text not null,
      uploaded_at integer not null,
      checksum text,
      ip text not null,
      delete_key text not null,
      thumbnail text,
      PRIMARY KEY(filename)
      )
    SQL

    SQL.exec(request)
  end

  # -------------------
  #  Insert / Delete
  # -------------------

  def insert(fileinfo : Fileinfo) : Nil
    request = <<-SQL
      INSERT INTO files
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      ON CONFLICT DO NOTHING
    SQL

    SQL.exec(request, *fileinfo.to_tuple)
  end

  def delete(filename : String) : Nil
    request = <<-SQL
      DELETE
      FROM files
      WHERE filename = ?
    SQL

    SQL.exec(request, filename)
  end

  def delete(fileinfo : Fileinfo) : Nil
    delete(fileinfo.filename)
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

  def select(filename : String) : Fileinfo?
    request = <<-SQL
      SELECT *
      FROM files
      WHERE filename = ?
    SQL

    SQL.query_one?(request, filename, as: Fileinfo)
  end

  def select(fileinfo : Fileinfo) : Nil
    self.select(fileinfo.filename)
  end

  def select_with_key(delete_key : String) : Fileinfo?
    request = <<-SQL
      SELECT *
      FROM files
      WHERE delete_key = ?
    SQL

    SQL.query_one?(request, delete_key, as: Fileinfo)
  end

  # -------------------
  #  Misc
  # -------------------

  def old_files : Array(Fileinfo)
    request = <<-SQL
      SELECT *
      FROM files
      WHERE uploaded_at < strftime('%s', 'now') - #{CONFIG.delete_files_after * 3600}
    SQL

    SQL.query_all(request, as: Fileinfo)
  end

  def file_count : Int32
    request = <<-SQL
      SELECT COUNT (filename)
      FROM files
    SQL

    SQL.query_one(request, as: Int32)
  end
end
