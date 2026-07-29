final: super: {
  pine64-pinephone = {
    qfirehose = final.callPackage ./qfirehose {};
    pinephone-keyboard = final.callPackage ./pinephone-keyboard {};
  };
}
