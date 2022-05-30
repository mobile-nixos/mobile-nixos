{
  mobile-nixos
, fetchFromGitHub
, ...
}:

mobile-nixos.kernel-builder {
  version = "5.16.0";
  configfile = ./config.armv7l;

  src = fetchFromGitHub {
    owner = "akemnade";
    repo = "linux";
    rev = "9be9fd52253701860b03e0d31557021943d7e0a0";
    sha256 = "1idqpynhifll9hq4m5kv38z19kkk4222zw6sa3a5lxvrai4484l1";
  };
}
