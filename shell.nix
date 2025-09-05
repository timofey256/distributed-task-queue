{ pkgs ? import <nixpkgs> {} }:

let
  haskell = pkgs.haskellPackages;
in
pkgs.mkShell {
  name = "distributed-task-queue-shell";

  buildInputs = [
    (haskell.ghcWithPackages (p: with p; [
      # core tools
      cabal-install
      haskell-language-server

      # project dependencies (from .cabal file)
      aeson
      bytestring
      text
      uuid
      yaml
      unordered-containers
      hashable
      hw-kafka-client
    ]))
    pkgs.zlib
    pkgs.pkg-config
    pkgs.python314
    pkgs.nodejs_22
  ];

  shellHook = ''
    echo "Welcome to distributed-task-queue dev shell!"
    echo "Run 'cabal update' once, then 'cabal build'."
  '';
}

