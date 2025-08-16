class EndpointDisabled < Exception
  def message : String
    return "Endpoint disabled"
  end
end

class DeletionKeyNotFound < Exception
  def message : String
    return "Deletion key not found."
  end
end

class FileNotFound < Exception
  def message : String
    return "File not found in the database."
  end
end

class NoFileProvided < Exception
  def message : String
    return "No file provided"
  end
end

class ExtensionNotAllowed < Exception
  getter extension : String

  def initialize(@extension)
  end

  def message : String
    return "Extension '#{extension}' is not allowed"
  end
end

class DBError < Exception
  def message : String
    return "An error ocurred when trying to insert the data into the DB"
  end
end
