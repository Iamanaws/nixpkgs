{
  lib,
  stdenv,
  fetchFromGitHub,
  clang,
  llvm,
  gnumake,
  acl,
  bzip2,
  zlib,
  musl-fts,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "netbase";
  version = "0.1-unstable-2026-02-21";

  src = fetchFromGitHub {
    owner = "littlefly365";
    repo = "Netbase";
    rev = "4e4acc839fc31f2f2ea9ca68e875773b43eccd9c";
    hash = "sha256-tLdHEzCdH6MPe6eBXTzLDLg25WdBPU8eRW+HrSd/m9c=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    clang
    llvm
    gnumake
  ];

  buildInputs = [
    acl
    bzip2
    zlib
  ]
  ++ lib.optionals stdenv.hostPlatform.isMusl [ musl-fts ];

  env = lib.optionalAttrs stdenv.hostPlatform.isMusl {
    NIX_CFLAGS_COMPILE = "-I${musl-fts}/include";
    NIX_LDFLAGS = "-L${musl-fts}/lib";
  };

  postPatch = ''
    substituteInPlace bin/ksh/Makefile \
      --replace-fail '$(pwd)' '$(CURDIR)'
  '';

  buildPhase = ''
    runHook preBuild
    [ -f scripts/linux/extattr.h ] && cp scripts/linux/extattr.h include/sys/
  ''
  + lib.optionalString stdenv.hostPlatform.isMusl ''
    mkdir -p include/protocols include/sys

    [ -f scripts/musl/cdefs.h ] && cp scripts/musl/cdefs.h include/sys/
    [ -f scripts/musl/queue.h ] && cp scripts/musl/queue.h include/sys/
    [ -f scripts/musl/timed.h ] && cp scripts/musl/timed.h include/protocols/

    export LDFTS="-lfts"
  ''
  + ''
    make -f GNUmakefile -j$NIX_BUILD_CORES
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    for dir in build/bin build/sbin build/usr.bin; do
      if [ -d "$dir" ]; then
        for prog in "$dir"/*; do
          [ -f "$prog" ] || continue
          install -m755 "$prog" "$out/bin/$(basename "$prog")"
        done
      fi
    done

    runHook postInstall
  '';

  meta = {
    description = "Port of NetBSD userland utilities";
    homepage = "https://github.com/littlefly365/Netbase";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ iamanaws ];
    platforms = lib.platforms.linux;
  };
})
