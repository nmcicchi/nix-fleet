final: prev:
let
  # nixpkgs version whose HTML snapshot tests fail
  brokenVersion = "10.5.1";
in {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (pself: psuper: {
      diff-cover =
        prev.lib.warnIf (psuper.diff-cover.version != brokenVersion) ''
          diff-cover in nixpkgs-unstable is now ${psuper.diff-cover.version} (was ${brokenVersion} when the test skip was added).
          Try removing the override in overlays/unstable.nix and rebuilding to see if the tests pass now.
        '' (psuper.diff-cover.overridePythonAttrs (old: {
          disabledTests = (old.disabledTests or []) ++ [
            "test_added_file_pycodestyle_html"
            "test_all_reports"
            "test_added_file_pyflakes_html"
            "test_added_file_pylint_html"
            "test_fail_under_html"
            "test_fail_under_pass_html"
          ];
        }));
    })
  ];
}
