{
  description = "Rust project flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        (_: {
          perSystem = { config, self', inputs', pkgs, system, ... }:
            let
              toolchain = inputs.fenix.packages.${system}.toolchainOf {
                channel = "nightly";
                date = "2024-02-08";
                # sha256 = pkgs.lib.fakeSha256;
                sha256 = "utKN+tK6/eNAgwC3SiYTmBXXOeWiZYEF3PK8amNePNo=";
              };
              rustToolchain = inputs.fenix.packages.${system}.combine
                (with inputs.fenix.packages.${system}; [
                  toolchain.cargo
                  toolchain.rustc

                  targets.wasm32-unknown-unknown.latest.rust-std
                ]);
              overlays = [
                inputs.fenix.overlays.default
                (final: prev: {
                  rustToolchain = rustToolchain;
                  buildRustPackage = (prev.makeRustPlatform {
                    cargo = rustToolchain;
                    rustc = rustToolchain;
                  }).buildRustPackage;
                })
              ];
            in {
              _module.args = {
                pkgs = import inputs.nixpkgs {
                  inherit system overlays;
                  config.allowUnfree = true;
                };
              };
            };
        })
      ];

      systems = [ "x86_64-linux" ];
      perSystem = { config, system, pkgs, ... }: {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            rustToolchain
            cargo-nextest
            cargo-watch
            bun
            just
            pkg-config
          ];
          shellHook = ''
            export PKG_CONFIG_PATH="${pkgs.openssl.dev}/lib/pkgconfig"
          '';

        };

      };
    };
}

