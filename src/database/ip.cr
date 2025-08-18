module Database::IPS
  extend self
  Log = ::Log.for(self)
  nodeProperties
  Utils::DB.database_create

  def create_table : Nil
    request = <<-SQL
      CREATE TABLE
      IF NOT EXISTS #{TABLE_NAME}
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
      INTO #{TABLE_NAME}
      VALUES ($1, $2, $3)
    SQL

    SQL.exec(request, *ip.to_tuple)
  end

  def delete(ip : String) : Nil
    request = <<-SQL
      DELETE
      FROM #{TABLE_NAME}
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
      FROM #{TABLE_NAME}
      WHERE ip = ?
    SQL

    SQL.query_one?(request, ip, as: UIP)
  end

  # -------------------
  #  Update
  # -------------------

  def increase_count(ip : UIP) : Nil
    request = <<-SQL
      UPDATE #{TABLE_NAME}
      SET count = count + 1
      WHERE ip = $1
    SQL

    SQL.exec(request, ip.ip)
  end
end
