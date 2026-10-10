class EndpointDisabled < Exception
  def message : String
<<<<<<< HEAD
    return "Endpoint disabled"
=======
    "Endpoint disabled"
>>>>>>> upstream/master
  end
end

class DeletionKeyNotFound < Exception
  def message : String
<<<<<<< HEAD
    return "Deletion key not found."
=======
    "Deletion key not found."
>>>>>>> upstream/master
  end
end

class FileNotFound < Exception
  def message : String
<<<<<<< HEAD
    return "File not found in the database."
=======
    "File not found in the database."
>>>>>>> upstream/master
  end
end

class NoFileProvided < Exception
  def message : String
<<<<<<< HEAD
    return "No file provided"
=======
    "No file provided"
  end
end

class EmptyFile < Exception
  def message : String
    "File is empty"
>>>>>>> upstream/master
  end
end

class ExtensionNotAllowed < Exception
  getter extension : String

  def initialize(@extension)
  end

  def message : String
<<<<<<< HEAD
    return "Extension '#{extension}' is not allowed"
=======
    "Extension '#{extension}' is not allowed"
>>>>>>> upstream/master
  end
end

class DBError < Exception
  def message : String
<<<<<<< HEAD
    return "An error ocurred when trying to insert the data into the DB"
=======
    "An error ocurred when trying to insert the data into the DB"
>>>>>>> upstream/master
  end
end
