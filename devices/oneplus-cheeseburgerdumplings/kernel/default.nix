{
	mobile-nixos
,	fetchFromGitHub
,	kernelPatches ? [] # FIXME
,	buildPackages
,	dtbTool
}:

let
	inherit (buildPackages) dtc;
in
		   
	(mobile-nixos.kernel-builder-gcc6 {
		configfile = ./config.aarch64;
		file = "Image.gz-dtb";
		hasDTB = true;
				
		version = "4.4.211-lineage";
		src = fetchFromGitHub {
			owner = "android-linux-stable";
			repo = "op5";
			rev = "607bd717e602f6326ad40974d2f382db183633d2";
			sha256 = "0kxg1fj8y7r8fpzj86y2v7kkwxcmr0wx282lhrmpkjwyj9cs6wh9";
		};

	patches = [
		./01_more_precise_arch.patch # May not be needed in future
		./0001-use-relative-header-includes.patch
		./0002-fix-TRACE_INCLUDE_PATH-paths.patch
		./0003-fix-synaptics_s3320-touchscreen-driver-input.patch
		./0004-disable-interfering-bt_power-rfkill.patch
		./0005-update-msm8998-qpnp-rtc-driver-src-with-sm8150.patch
		./0006-disable-various-spammy-driver-logging.patch
	];

	
	postPatch = ''
    # Remove -Werror from all makefiles
    local i
    local makefiles="$(find . -type f -name Makefile)
    $(find . -type f -name Kbuild)"
    for i in $makefiles; do
      sed -i 's/-Werror-/-W/g' "$i"
      sed -i 's/-Werror//g' "$i"
    done
    echo "Patched out -Werror"
  '';

  makeFlags = [ "DTC_EXT=${dtc}/bin/dtc"];

  isModular = false;

}).overrideAttrs ({ postInstall ? "", postPatch ? "", ... }: {
  installTargets = [ "Image.gz" "zinstall" "Image.gz-dtb" "install" ];
  postInstall = postInstall + ''
    cp $buildRoot/arch/arm64/boot/Image.gz-dtb $out/
  '';
})
