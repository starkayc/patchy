class EndpointDisabled < Exception
  def message : String
    "Endpoint disabled"
  end
end

class DeletionKeyNotFound < Exception
  def message : String
    "Deletion key not found."
  end
end

class FileNotFound < Exception
  def message : String
    "File not found in the database."
  end
end

class NoFileProvided < Exception
  def message : String
    "No file provided"
  end
end

class EmptyFile < Exception
  def message : String
    "File is empty"
  end
end

class ExtensionNotAllowed < Exception
  getter extension : String

  def initialize(@extension)
  end

  def message : String
    "Extension '#{extension}' is not allowed"
  end
end

class DBError < Exception
  def message : String
    "An error ocurred when trying to insert the data into the DB"
  end
end
