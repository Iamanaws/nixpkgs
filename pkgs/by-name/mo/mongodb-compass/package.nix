{
  lib,
  stdenv,
  stdenvNoCC,
  buildNpmPackage,
  fetchFromGitHub,
  makeDesktopItem,
  copyDesktopItems,
  makeWrapper,
  nodejs_22,
  electron_38,
  python3,
  pkg-config,
  libsecret,
  krb5,
  zip,
  xcodebuild,
}:

let
  electron = electron_38;
  nodePlatform = stdenv.hostPlatform.node.platform;
  nodeArch = stdenv.hostPlatform.node.arch;

  electron-dist-zip = stdenvNoCC.mkDerivation {
    pname = "electron-dist-zip";
    version = electron.version;
    src = electron.dist;
    nativeBuildInputs = [ zip ];
    buildPhase = ''
      zip --recurse-paths - . > $out
    '';
    dontInstall = true;
  };
in
buildNpmPackage (finalAttrs: {
  pname = "mongodb-compass";
  version = "1.49.4";

  src = fetchFromGitHub {
    owner = "mongodb-js";
    repo = "compass";
    tag = "v${finalAttrs.version}";
    hash = "sha256-wMYEEzABSB5c3pYKRAGLoewqoEB877bP260G/ZBpaLQ=";
  };

  nodejs = nodejs_22;
  npmDepsHash = "sha256-m6bZXgu82PlXk5dh1JAGZRVVNaEJHVVksRhFCmG3rx8=";
  npmFlags = [ "--ignore-scripts" ];
  npmWorkspace = "packages/compass";

  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
    ELECTRON_OVERRIDE_DIST_PATH = "${electron.dist}";
    HADRON_SKIP_INSTALLER = "true";
    HADRON_DISTRIBUTION = "compass";
    CI = "true";
  }
  // lib.optionalAttrs stdenv.hostPlatform.isDarwin {
    CSC_IDENTITY_AUTO_DISCOVERY = "false";
  };

  nativeBuildInputs = [
    makeWrapper
    python3
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    copyDesktopItems
    pkg-config
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    xcodebuild
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    libsecret
    krb5
  ];

  postPatch = ''
    substituteInPlace packages/compass/src/app/styles/index.less \
      --replace-fail "@import './fonts.less';" ""

    substituteInPlace packages/hadron-build/lib/target.js \
      --replace-fail "electronVersion: this.electronVersion," \
        "electronVersion: this.electronVersion, electronZipDir: process.env.ELECTRON_ZIP_DIR," \
      --replace-fail "afterExtract: [ffmpegAfterExtract]," "afterExtract: [],"

    substituteInPlace packages/hadron-build/commands/release.js \
      --replace-fail "task('install dependencies', installDependencies)," ""
  '';

  postConfigure = ''
    patchShebangs node_modules/.bin packages/compass/node_modules/.bin packages configs scripts

    # Running from wrapped electron sets argv[1] to resources/app, which Compass
    # would otherwise treat as a connection string.
    substituteInPlace node_modules/compass-preferences-model/src/global-config.ts \
      --replace-fail "const argvStartIndex = process.versions.electron && !process.defaultApp ? 1 : 2;" \
        "const argvStartIndex = process.versions.electron && !process.defaultApp && !/([\\\\/]|^)electron(\\\\.exe)?$/.test(process.execPath) ? 1 : 2;" \
      --replace-fail "const ignoreFlags = /^(disableGpu$|sandbox$|squirrel)/;" \
        "const ignoreFlags = /^(disableGpu$|sandbox$|squirrel|ozonePlatformHint$|enableFeatures$|enableWaylandIme$|waylandTextInputVersion$)/;" \
      --replace-fail "result.positionalArguments = result._;" \
        "result.positionalArguments = result._.filter((arg) => !/[\\\\/]resources[\\\\/]app(\\\\.asar)?$/.test(String(arg)));"

    electronVersion="$(node -p "require('./node_modules/electron/package.json').version")"
    export ELECTRON_ZIP_DIR="$PWD/.electron-zip"
    mkdir -p "$ELECTRON_ZIP_DIR"
    cp ${electron-dist-zip} "$ELECTRON_ZIP_DIR/electron-v$electronVersion-${nodePlatform}-${nodeArch}.zip"
  '';

  preBuild = ''
    export npm_config_nodedir=${electron.headers}
    for nativeModule in cpu-features keytar kerberos interruptor os-dns-native native-machine-id
    do
      if [ -d "node_modules/$nativeModule" ]; then
        pushd "node_modules/$nativeModule"
        if [ -f buildcheck.js ] && [ ! -f buildcheck.gypi ]; then
          node buildcheck.js > buildcheck.gypi
        fi
        if [ -f binding.gyp ]; then
          npm exec node-gyp rebuild
        fi
        popd
      fi
    done

    npm run compile --workspace=@mongodb-js/webpack-config-compass
    npm run compile --workspace=mongodb-compass
  '';

  npmBuildScript = "package-compass-debug";

  preInstall = lib.optionalString stdenv.hostPlatform.isLinux ''
    # Keep only runtime deps and drop node-gyp intermediates that cause noisy fixup logs.
    npm prune --omit=dev --workspace=mongodb-compass --ignore-scripts
    find node_modules -type d -name obj.target -prune -exec rm -rf {} +
    find node_modules -type f \( -name "*.o" -o -name "*.a" \) -delete
  '';

  installPhase = ''
    runHook preInstall
  ''
  + lib.optionalString stdenv.hostPlatform.isDarwin ''
    mkdir -p "$out/Applications" "$out/bin"
    cp -r packages/compass/dist/mac*/MongoDB\ Compass.app "$out/Applications"
    makeWrapper "$out/Applications/MongoDB Compass.app/Contents/MacOS/MongoDB Compass" "$out/bin/${finalAttrs.pname}"
  ''
  + lib.optionalString stdenv.hostPlatform.isLinux ''
    mkdir -p $out/share/mongodb-compass $out/bin
    cp -r "packages/compass/dist/MongoDB Compass-linux-${nodeArch}/resources" "$out/share/mongodb-compass"

    if [ -d "$out/share/mongodb-compass/resources/app" ]; then
      cp -rL node_modules "$out/share/mongodb-compass/resources/app/"
    fi

    appEntry="$out/share/mongodb-compass/resources/app.asar"
    if [ ! -e "$appEntry" ]; then
      appEntry="$out/share/mongodb-compass/resources/app"
    fi

    install -Dm444 packages/compass/app-icons/linux/mongodb-compass-logo-stable.png \
      $out/share/icons/hicolor/1024x1024/apps/mongodb-compass.png

    cat > "$out/bin/${finalAttrs.pname}" <<EOF
    #!${stdenv.shell}
    set -e

    export ELECTRON_FORCE_IS_PACKAGED=\''${ELECTRON_FORCE_IS_PACKAGED-1}

    extraFlags=()
    if [ -n "\''${MONGODB_COMPASS_PASSWORD_STORE-}" ]; then
      extraFlags+=(--password-store="\$MONGODB_COMPASS_PASSWORD_STORE")
    else
      desktop="\''${XDG_CURRENT_DESKTOP-}:\''${DESKTOP_SESSION-}"
      case "\''${desktop,,}" in
        *kde*|*plasma*)
          extraFlags+=(--password-store=kwallet6)
          ;;
        *)
          extraFlags+=(--password-store=gnome-libsecret)
          ;;
      esac
    fi

    if [ -n "\''${NIXOS_OZONE_WL-}" ] && [ -n "\''${WAYLAND_DISPLAY-}" ]; then
      extraFlags+=(--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true)
    fi

    exec '${lib.getExe electron}' "\''${extraFlags[@]}" "$appEntry" "\$@"
    EOF
    chmod +x "$out/bin/${finalAttrs.pname}"
  ''
  + ''
    runHook postInstall
  '';

  desktopItems = lib.optionals stdenv.hostPlatform.isLinux [
    (makeDesktopItem {
      name = "mongodb-compass";
      desktopName = "MongoDB Compass";
      exec = "${finalAttrs.pname} %U";
      icon = "mongodb-compass";
      comment = "GUI for MongoDB";
      categories = [
        "Development"
        "Database"
      ];
    })
  ];

  passthru.updateScript = ./update.sh;

  meta = {
    description = "GUI for MongoDB";
    homepage = "https://github.com/mongodb-js/compass";
    license = lib.licenses.sspl;
    mainProgram = "mongodb-compass";
    maintainers = with lib.maintainers; [
      friedow
      iamanaws
    ];
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
  };
})
