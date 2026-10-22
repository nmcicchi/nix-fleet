final: prev: {
  python314Packages = prev.python314Packages.override {
    overrides = pself: psuper: {
      diff-cover =
        let
          # Expires once upstream Nixpkgs updates past the broken 10.5.1 release
          isFixedUpstream = prev.lib.versionAtLeast psuper.diff-cover.version "10.5.2";
        in
        prev.lib.warnIf isFixedUpstream ''
          diff-cover >= 10.5.2 is now in nixpkgs, the version pin override can be removed.
        ''
          (if isFixedUpstream then
            psuper.diff-cover
          else
            # Pinning back to 10.5.0 until upstream fixes 10.5.1 on Python 3.14
            psuper.diff-cover.overrideAttrs (old: rec {
              version = "10.5.0";
              src = prev.fetchPypi {
                pname = "diff_cover";
                inherit version;
                hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # replace with actual hash or pkgs.lib.fakeHash
              };
            })
          );
    };
  };
}
