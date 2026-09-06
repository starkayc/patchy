<<<<<<< HEAD
class PublicAssets
  extend BakedFileSystem
  bake_folder "../public", compression: false
end

class Locales
  extend BakedFileSystem
  bake_folder "../locales", compression: false
=======
module BakedFiles
  class PublicAssets
    extend BakedFileSystem
    bake_folder "../public", compression: false
  end

  class Locales
    extend BakedFileSystem
    bake_folder "../locales", compression: false
  end
>>>>>>> upstream/master
end
