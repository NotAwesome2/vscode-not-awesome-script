{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;

      nodeManifest = lib.importJSON ./package.json;

      revSuffix = lib.optionalString (self ? dirtyShortRev)
        "-${self.dirtyShortRev}";

      makePackages = (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

          src = lib.sourceByRegex ./. [
            "^\.vscodeignore$"
            "^README\.md$"
            "^eslint\.config\.mjs$"
            "^language-configuration\.json$"
            "^package-lock\.json$"
            "^package\.json$"
            "^snippets(/.*)?$"
            "^src(/.*)?$"
            "^syntaxes(/.*)?$"
            "^tsconfig\.json$"
          ];

          # Inputs needed to compile vsce's native deps (keytar -> libsecret)
          # under nodejs node-gyp. Shared between the package build and the
          # devShell's node_modules build.
          npmNativeDeps = {
            nativeBuildInputs = [ pkgs.pkg-config ];
            buildInputs = [ pkgs.libsecret ];
          };
        in
        {
          packages.default = pkgs.buildNpmPackage ({
            pname = nodeManifest.name;
            version = nodeManifest.version + revSuffix;

            inherit src;

            npmConfigHook = pkgs.importNpmLock.npmConfigHook;
            npmDeps = pkgs.importNpmLock {
              npmRoot = src;
            };

            npmBuildScript = "compile";

            doCheck = true;
            checkPhase = ''
              runHook preCheck
              npm run lint
              runHook postCheck
            '';

            installPhase = ''
              runHook preInstall
              npm run package -- --out "$out"
              runHook postInstall
            '';
          } // npmNativeDeps);

          devShells.default = pkgs.mkShell {
            npmDeps = pkgs.importNpmLock.buildNodeModules {
              npmRoot = src;
              inherit (pkgs) nodejs;
              derivationArgs = npmNativeDeps;
            };
            nativeBuildInputs = [
              pkgs.nodejs
              pkgs.importNpmLock.linkNodeModulesHook
            ];
          };
        }
      );
    in
    builtins.foldl' lib.recursiveUpdate { } (builtins.map
      (system:
        let
          result = makePackages system;
        in
        {
          packages.${system} = result.packages;
          devShells.${system} = result.devShells;
        }
      )
      lib.systems.flakeExposed);
}
