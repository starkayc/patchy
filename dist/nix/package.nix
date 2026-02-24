{
  crystal_1_19,
  pkg-config,
  fetchgit,
  git,
  shards,
  sqlite,
  openssl,
}:

let
  crystal = crystal_1_19;
in
crystal.buildCrystalPackage rec {
  pname = "patchy";
  version = "0.9.9";
  src = fetchgit {
    url = "https://codeberg.org/Fijxu/patchy";
    leaveDotGit = true;
    hash = "sha256-+zcR/NRSjuCuMqokuUZqrscSDFzFwJJ70o9iokHz0rU=";
  };

  doCheck = false;
  doInstallCheck = false;

  nativeBuildInputs = [
    pkg-config
    git
    shards
  ];

  buildInputs = [
    openssl
    sqlite
  ];

  format = "crystal";
  shardsFile = ./shards.nix;
  crystalBinaries.patchy = {
    src = "src/patchy.cr";
    options = [
      "--release"
      "--progress"
      "--stats"
      "--time"
      "--error-trace"
      "--warnings all"
    ];
  };
}
