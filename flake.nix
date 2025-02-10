{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
        flake-utils = {
          follows = "flake-utils";
        };
      };
    };
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    rust-overlay,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        overlays = [(import rust-overlay)];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        rustToolchain = (pkgs.pkgsBuildHost.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml).override {
          extensions = ["rust-src" "clippy" "llvm-tools"];
        };
        buildInputs = with pkgs; [
          coreutils
          bash
          openssl
          pkg-config
        ];
        nativeBuildInputs = with pkgs; [
          rustToolchain
          rust-analyzer
        ];
      in {
        packages = {
          default = self.packages.${system}.gpu-usage-waybar;
          gpu-usage-waybar = pkgs.rustPlatform.buildRustPackage {
            pname = "gpu-usage-waybar";
            version = "0.1.2";
            src = ./.;
            cargoSha256 = "sha256-TOV+0cB2OmtsixBBLGYod1YJckx9a2Ar+uJWcKGqM/0=";
          };
        };
        devShell = pkgs.mkShell {
          inherit buildInputs nativeBuildInputs;
          RUST_BACKTRACE = 1;
          RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
        };
      }
    );
}
