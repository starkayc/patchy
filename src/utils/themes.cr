module Utils::Themes
  extend self

  @@themes : Array(String) = [] of String

  def init
    self.load_themes
  end

  private def load_themes
    Log.info &.emit("Loading themes...")
    available_theme_files = BakedFiles::BuiltInThemes.files
    # Add default theme
    @@themes << "Default"
    available_theme_files.each do |file|
      theme_file = file.path[1..]
      split_theme_file_name = theme_file.split(".")
      # To remove the extension while preserving the dots if the filename has any dots
      theme_name = split_theme_file_name[0..-2].join(".")
      @@themes << theme_name
      Log.info &.emit("Theme '#{theme_name}' loaded!")
    end
  end

  def themes
    @@themes
  end
end
