In-depth tests
==============

Those are rather bulky integration-type tests. They are not ran by default, but
should be used to better test the image builder infrastructure.

Changes to the infra should be passed through this test suite in addition to the
slimmer usual tests suite.

> **Tip:**
>
> From the image-builder infra directory, run the following.
> 
> ```
> nix-build in-depth-tests/[...].nix -I nixpkgs-overlays=$PWD/lib/tests/test-overlay.nix
> ```
>
> This allows you to track the bigger builds more easily.

