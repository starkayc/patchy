module Database::IP
  extend self

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
