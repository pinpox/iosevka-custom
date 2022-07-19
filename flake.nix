{
  description = "Iosevka - custom variant";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, flake-compat }:
    let
      allSystems = flake-utils.lib.eachDefaultSystem
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};


            plainPackage =
              let
                iosevkaWithWeb = pkgs.iosevka.overrideAttrs (finalAttrs: previousAttrs: {
                  # Replace `ttf::$pname with `contents::$pname` in buildPhase to get webfont aswell
                  # See https://typeof.net/Iosevka/customizer for more options
                  buildPhase = ''
                    echo "exoprting"
                    export HOME=$TMPDIR
                    echo "hook"
                    runHook preBuild
                    echo "build"
                    npm run build --no-update-notifier -- --jCmd=$NIX_BUILD_CORES contents::$pname 
                    echo "post"
                    runHook postBuild
                    echo "end"
                  '';
                });
              in
              iosevkaWithWeb.override {
                privateBuildPlan = builtins.readFile ./iosevka-qp.toml;
                set = "qp";
              };

            # nerdFontPackage = let outDir = "$out/share/fonts/truetype/"; in
            # pkgs.stdenv.mkDerivation {
            # pname = "iosevka-qp-nerd-font";
            # version = plainPackage.version;

            # src = builtins.path { path = ./.; name = "iosevka-qp"; };

            # buildInputs = [ pkgs.nerd-font-patcher ];

            # configurePhase = "mkdir -p ${outDir}";
            # buildPhase = ''
            #   for fontfile in ${plainPackage}/share/fonts/truetype/*
            #   do
            #   nerd-font-patcher $fontfile --complete --careful --outputdir ${outDir}
            #   done
            # '';
            # dontInstall = true;
            # };

            packages = {
              normal = plainPackage;
              # nerd-font = nerdFontPackage;
            };
          in
          {
            inherit packages;
            defaultPackage = plainPackage;
          }
        );
    in
    {
      packages = allSystems.packages;
      defaultPackage = allSystems.defaultPackage;
      overlay = final: prev: {
        iosevka-qp = allSystems.packages.${final.system}; # either `normal` or `nerd-font`
      };
    };
}
