class PublicAssets
  extend BakedFileSystem
  bake_folder "../public"
end

class Locales
  extend BakedFileSystem
  bake_folder "../locales"
end
