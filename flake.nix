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


            # nerdFontPackage = let outDir = "$out/share/fonts/truetype/"; in
            # pkgs.stdenv.mkDerivation {
            # pname = "iosevka-qp-nerd-font";
            # version =iosevka-qp.version;

            # src = builtins.path { path = ./.; name = "iosevka-qp"; };

            # buildInputs = [ pkgs.nerd-font-patcher ];

            # configurePhase = "mkdir -p ${outDir}";
            # buildPhase = ''
            #   for fontfile in ${iosevka-qp}/share/fonts/truetype/*
            #   do
            #   nerd-font-patcher $fontfile --complete --careful --outputdir ${outDir}
            #   done
            # '';
            # dontInstall = true;
            # };

          in
          {
            packages =
              let
                # Replace `ttf::$pname with `contents::$pname` in buildPhase to get webfont aswell
                # See https://typeof.net/Iosevka/customizer for more options
                buildPhase = ''
                  export HOME=$TMPDIR
                  runHook preBuild
                  npm run build --no-update-notifier -- --jCmd=$NIX_BUILD_CORES contents::$pname
                  runHook postBuild
                '';

                # Override installPhase to copy the addional woff2 and css files
                installPhase = ''
                  runHook preInstall
                  fontdir="$out/share/fonts"
                  mkdir -p "$fontdir"
                  cp -r "dist/$pname"/* "$fontdir"
                  runHook postInstall
                '';

              in

              # Use https://typeof.net/Iosevka/customizer to generate build plan
              rec {
                iosevka-qp = (pkgs.iosevka.overrideAttrs (finalAttrs: previousAttrs: {
                  inherit buildPhase installPhase;
                })).override {
                  privateBuildPlan = builtins.readFile ./iosevka-qp.toml;
                  set = "qp";
                };

                iosevka-fixed = pkgs.iosevka.overrideAttrs (finalAttrs: previousAttrs: {
                  inherit buildPhase installPhase;
                });

                # iosevka-fixed = (pkgs.iosevka.overrideAttrs (finalAttrs: previousAttrs: {
                #   inherit buildPhase installPhase;
                # })).override {
                #   privateBuildPlan = builtins.readFile ./iosevka-fixed.toml;
                #   set = "fixed";
                # };
                default = iosevka-fixed;
                # nerd-font = nerdFontPackage;
              };
          }
        );
    in
    {
      packages = allSystems.packages;
      overlay = final: prev: {
        iosevka-qp = allSystems.packages.${final.system}; # either `normal` or `nerd-font`
      };
    };
}
