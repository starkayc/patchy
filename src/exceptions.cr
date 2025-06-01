class EndpointDisabled < Exception
  def message
    return "Endpoint disabled"
  end
end

class DeletionKeyNotFound < Exception
  def message
    return "Deletion key not found."
  end
end

class FileNotFound < Exception
  def message
    return "File not found in the database."
  end
end

class NoFileProvided < Exception
  def message
    return "No file provided"
  end
end

class ExtensionNotAllowed < Exception
  getter extension : String

  def initialize(@extension)
  end

  def message
    return "Extension '#{extension}' is not allowed"
  end
end

class DBError < Exception
  def message
    return "An error ocurred when trying to insert the data into the DB"
  end
end
