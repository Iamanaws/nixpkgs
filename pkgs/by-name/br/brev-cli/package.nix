{
  lib,
  stdenv,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  versionCheckHook,
  writableTmpDirAsHomeHook,
}:

buildGoModule (finalAttrs: {
  pname = "brev-cli";
  version = "0.6.324";

  src = fetchFromGitHub {
    owner = "brevdev";
    repo = "brev-cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Gy7pL4GYO2a7Q3z3xarhXB2EGSzojYEmD4ynHBwQ/9Y=";
  };

  vendorHash = "sha256-rB6uqkpnc+SlbzNvtTOnDCIJIpxoiyPb/lsiRYkDltg=";

  env.CGO_ENABLED = 0;
  subPackages = [ "." ];

  nativeBuildInputs = [
    installShellFiles
  ];

  ldflags = [
    "-s"
    "-X github.com/brevdev/brev-cli/pkg/cmd/version.Version=${finalAttrs.src.tag}"
  ];

  postInstall = ''
    mv $out/bin/brev-cli $out/bin/brev
  ''
  + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    for shell in bash fish zsh; do
      installShellCompletion --cmd brev --"$shell" <("$out/bin/brev" completion "$shell")
    done
  '';

  nativeInstallCheckInputs = [
    versionCheckHook
    writableTmpDirAsHomeHook
  ];
  versionCheckProgramArg = "--version";
  versionCheckKeepEnvironment = [ "HOME" ];
  doInstallCheck = true;

  meta = {
    description = "Connect your laptop to cloud computers";
    longDescription = ''
      NVIDIA Brev provides streamlined access to NVIDIA GPU instances on
      popular cloud platforms, automatic environment setup, and flexible
      deployment options, enabling developers to start experimenting instantly.
    '';
    homepage = "https://github.com/brevdev/brev-cli";
    changelog = "https://github.com/brevdev/brev-cli/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ iamanaws ];
    mainProgram = "brev";
  };
})
