{
  lib,
  stdenv,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  versionCheckHook,
}:

buildGoModule (finalAttrs: {
  pname = "brev-cli";
  version = "0.6.316";

  src = fetchFromGitHub {
    owner = "brevdev";
    repo = "brev-cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-L1NpFbZXHxQQJzcLHkOIcCnHu9HRybM0R+Iz1qOheGs=";
  };

  vendorHash = "sha256-CzGuEbq4I1ygYQsoyyXC6gDBMLg21dKQTKkrbwpAR2U=";

  env.CGO_ENABLED = 0;
  subPackages = [ "." ];

  nativeBuildInputs = [
    installShellFiles
  ];

  ldflags = [
    "-s"
    "-X github.com/brevdev/brev-cli/pkg/cmd/version.Version=${finalAttrs.src.rev}"
  ];

  postInstall = ''
    mv $out/bin/brev-cli $out/bin/brev
  ''
  + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    for shell in bash fish zsh; do
      installShellCompletion --cmd brev --"$shell" <("$out/bin/brev" completion "$shell")
    done
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";
  doInstallCheck = true;

  meta = {
    description = "Connect your laptop to cloud computers";
    homepage = "https://github.com/brevdev/brev-cli";
    changelog = "https://github.com/brevdev/brev-cli/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ iamanaws ];
    mainProgram = "brev";
  };
})
