module Utils::DB
  extend self
  Log = ::Log.for(self)

  macro database_create
    def create : Nil
      if !Utils::DB.exists?(TABLE_NAME)
        begin
          Log.info &.emit("creating table '#{TABLE_NAME}'")
          create_table
        rescue ex
          Log.fatal &.emit("error creating table '#{TABLE_NAME}'", error: ex.message)
        end
      end
    end
  end

  def create_tables : Nil
    Database::Files.create
    Database::IPS.create
  end

  def load_pragmas : Nil
    SQL.exec("PRAGMA foreign_keys = ON")
  end

  def exists?(table_name : String) : Bool?
    request = <<-SQL
      SELECT EXISTS
      (
        SELECT 1 FROM
        sqlite_schema
        WHERE type = 'table'
        AND name = ?
      )
    SQL

    SQL.query_one(request, table_name, as: Bool?)
  end
end
