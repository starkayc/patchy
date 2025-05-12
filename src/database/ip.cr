module Database::IP
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
      AND name='ips'
      )
    SQL

    SQL.query_one(request, as: Bool?)
  end

  def create_table : Nil
    request = <<-SQL
      CREATE TABLE
      IF NOT EXISTS ips
      (
      ip text,
      count integer DEFAULT 0,
      date integer,
      PRIMARY KEY(ip)
      )
    SQL

    SQL.exec(request)
  end

  # -------------------
  #  Insert / Delete
  # -------------------

  def insert(ip : UIP) : DB::ExecResult
    request = <<-SQL
      INSERT OR IGNORE
      INTO ips
      VALUES ($1, $2, $3)
    SQL

    SQL.exec(request, *ip.to_tuple)
  end

  def delete(ip : String) : Nil
    request = <<-SQL
      DELETE
      FROM ips
      WHERE ip = ?
    SQL

    SQL.exec(request, ip)
  end

  # -------------------
  #  Select
  # -------------------

  def select(ip : String) : UIP?
    request = <<-SQL
      SELECT *
      FROM ips
      WHERE ip = ?
    SQL

    SQL.query_one?(request, ip, as: UIP)
  end

  # -------------------
  #  Update
  # -------------------

  def increase_count(ip : UIP) : Nil
    request = <<-SQL
      UPDATE ips
      SET count = count + 1
      WHERE ip = $1
    SQL

    SQL.exec(request, ip.ip)
  end
end
