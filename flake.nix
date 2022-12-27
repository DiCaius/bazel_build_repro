{
  description = "DirEnv Configuration.";

  inputs = {
    flake-utils-plus = {
      url = "github:gytis-ivaskevicius/flake-utils-plus/v1.3.1";
    };
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };
  };

  outputs = { flake-utils-plus, nixpkgs, self }:
    flake-utils-plus.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        bazel-fhs-env = pkgs.buildFHSUserEnv {
          name = "bazel-fhs-env";
          profile = ''
            pnpm install --lockfile-only
          '';
          runScript = ''bash'';
          targetPkgs = fhsPkgs: with fhsPkgs; [
            fhsPkgs.bazel_6
            fhsPkgs.gcc
            fhsPkgs.glibc
            fhsPkgs.nodePackages.pnpm
          ];
        };
        bazel-fhs-derivation = pkgs.stdenv.mkDerivation {
          installPhase = ''
            mkdir --parent $out
            cp -r ${bazel-fhs-env}/bin/bazel-fhs-env $out/bazel-fhs-env
          '';
          name = "bazel-fhs-derivation";
          nativeBuildInputs = [ bazel-fhs-env ];
          unpackPhase = "true";
        };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [ bazel-fhs-derivation ];
          shellHook = ''
            exec ${bazel-fhs-derivation}/bazel-fhs-env
          '';
        };
      }
    );
}