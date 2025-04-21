module Database::IP
  # -------------------
  #  Insert / Delete
  # -------------------

  def insert(ip : IP) : Nil
    request = <<-SQL
      INSERT OR IGNORE
      INTO ips (ip, date)
      VALUES ($1, $2)
      ON CONFLICT DO NOTHING
    SQL

    SQL.exec(request, *ip.to_tuple)
  end
end
