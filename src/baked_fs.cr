module BakedFiles
  class PublicAssets
    extend BakedFileSystem
    bake_folder "../public", compress: false
  end

  class Locales
    extend BakedFileSystem
    bake_folder "../locales", compress: false
  end
end
