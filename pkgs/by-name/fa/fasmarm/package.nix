{
  stdenv,
  lib,
  fetchzip,
  fasm,
  makeBinaryWrapper,
}:

let
  fasmarmSrc = fetchzip {
    url = "https://arm.flatassembler.net/FASMARM_small.ZIP";
    hash = "sha256-gy5Ypx+awJ1+TbMVEyN91Kam6H2tZ4NGVEAHmyz2V8E=";
    stripRoot = false;
    extension = "zip";
  };
in
stdenv.mkDerivation {
  pname = "fasmarm";
  version = "1.44";

  # FASMARM is a source overlay, not a loadable add-on, so it must be built as
  # a separate FASM-based executable.
  src = fasm.src;

  postUnpack = ''
    cp -r ${fasmarmSrc}/. "$sourceRoot"
  '';

  strictDeps = true;
  __structuredAttrs = true;

  outputs = [
    "out"
    "doc"
  ];

  nativeBuildInputs = [
    fasm
    makeBinaryWrapper
  ];

  buildPhase =
    let
      sourceDir = "source/linux${lib.optionalString stdenv.hostPlatform.isx86_64 "/x64"}";
    in
    ''
      runHook preBuild

      buildRoot=$PWD
      cd ${sourceDir}
      fasm -m 65536 fasmarm.asm "$buildRoot/fasmarm"
      cd "$buildRoot"

      runHook postBuild
    '';

  installPhase = ''
    runHook preInstall

    install -Dm755 fasmarm $out/bin/fasmarm

    mkdir -p $doc/share/doc/fasmarm
    # Both licenses require reproducing their notices with binary distributions.
    install -Dm644 license.txt $doc/share/doc/fasmarm/LICENSE.fasm
    sed -n '1,34p' source/armv8.inc > $doc/share/doc/fasmarm/LICENSE.fasmarm
    install -Dm644 ReadMe.txt $doc/share/doc/fasmarm/README

    mkdir -p $out/share/fasmarm
    cp -r include $out/share/fasmarm

    wrapProgram $out/bin/fasmarm \
      --set-default INCLUDE "$out/share/fasmarm/include"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    cat > test.asm <<'EOF'
    include 'macro/armstruc.inc'
    processor cpu64_v8
    code64
    mov x0,42
    EOF
    printf '\x40\x05\x80\xd2' > expected.bin

    $out/bin/fasmarm test.asm test.bin
    cmp expected.bin test.bin

    runHook postInstallCheck
  '';

  meta = {
    description = "FASM-based assembler for 32-bit and 64-bit ARM processors";
    homepage = "https://arm.flatassembler.net/";
    license = lib.licenses.bsd2;
    mainProgram = "fasmarm";
    maintainers = with lib.maintainers; [
      evanwporter
      iamanaws
    ];
    platforms = [
      "x86_64-linux"
      "i686-linux"
    ];
  };
}
