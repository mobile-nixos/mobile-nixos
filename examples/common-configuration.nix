{ lib, ... }:

{
  # Ensures all example systems float up normalization issues by default.
  mobile.boot.stage-1.kernel.useStrictKernelConfig = lib.mkDefault true;
}
