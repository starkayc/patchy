module BakedFiles
  class PublicAssets
    extend BakedFileSystem
    bake_folder "../public", compression: false
  end

  class Locales
    extend BakedFileSystem
    bake_folder "../locales", compression: false
  end

  class BuiltInThemes
    extend BakedFileSystem
    bake_folder "../public/-/assets/css/builtInThemes", compression: false
  end
end
