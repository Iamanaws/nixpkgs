# shellcheck shell=bash

electronWrapHook() {
  echo "Running electronWrapHook..."

  local pathToWrap findResult cmdProgram
  local -a validBundles

  # Auto-detect .app bundles if electronWrapAppBundle is not explicitly set
  if [[ ! -v electronWrapAppBundle ]]; then
    validBundles=()
    mapfile -t -d $'\0' findResult < <(find "${!outputBin:?}" -maxdepth 3 -type d -name "*.app" -print0)
    for bundle in "${findResult[@]}"; do
      if [[ -d "$bundle/Contents/MacOS" ]]; then
        validBundles+=("$bundle")
      fi
    done
    if [[ ${#validBundles[@]} -eq 1 ]]; then
      electronWrapAppBundle="${validBundles[0]}"
      echo "electronWrapHook: auto-detected app bundle '${electronWrapAppBundle}'"
    fi
  fi

  # Check if the var is set, if so just use it.
  if [[ -v electronWrapPath ]]; then
    # Use the user input
    pathToWrap="$electronWrapPath"
  elif [[ ! -v electronWrapAppBundle ]]; then
    # If electronWrapPath is not set...
    #
    # Look for files named "app.asar", output results as null-terminated string, and store each string to an array
    mapfile -t -d $'\0' findResult < <(find "${!outputBin:?}" -type f -a -name "app.asar" -print0)

    # Ensure only one is found
    if [[ ${#findResult[@]} -eq 0 ]]; then
      echo "electronWrapHook: did not find 'app.asar' in the bin output. Please supply the path to it with 'electronWrapPath'"
      exit 1
    elif [[ ${#findResult[@]} -gt 1 ]]; then
      echo "electronWrapHook: found multiple 'app.asar' files:"
      echo "${findResult[*]}"
      echo "Please supply the path to wrap with 'electronWrapPath'"
      exit 1
    else
      # If there is only exactly one result, use it.
      pathToWrap="${findResult[0]}"
    fi
  fi

  # Check if electronWrapperName is set, and use that unconditionally if so.
  if [[ -v electronWrapperName ]]; then
    # User input
    cmdProgram="$electronWrapperName"
  elif [[ -v NIX_MAIN_PROGRAM ]]; then
    # If not, check if meta.mainProgram has been set.
    cmdProgram="$NIX_MAIN_PROGRAM"
  else
    # If neither...
    echo "electronWrapHook: \$mainProgram is not set so we don't know how to set the binary name."
    echo "  To fix this set \`meta.mainProgram\` or \`electronWrapperName\`"
    exit 1
  fi

  # App bundle mode for Darwin
  # The built .app already contains the electron binary and the .asar,
  # so we wrap the bundle executable directly
  if [[ -v electronWrapAppBundle ]]; then
    local appBundleMacOSDir="$electronWrapAppBundle/Contents/MacOS"
    local wrappedProgram

    if [[ ! -d "$appBundleMacOSDir" ]]; then
      echo "electronWrapHook: app bundle '$electronWrapAppBundle' does not contain 'Contents/MacOS'"
      exit 1
    fi

    if [[ -v electronWrapAppExecutableName ]]; then
      wrappedProgram="$appBundleMacOSDir/$electronWrapAppExecutableName"
      if [[ ! -x "$wrappedProgram" ]]; then
        echo "electronWrapHook: app executable '$wrappedProgram' does not exist or is not executable"
        exit 1
      fi
    else
      # Try to infer from mainProgram first, then auto-detect
      if [[ -x "$appBundleMacOSDir/$cmdProgram" ]]; then
        wrappedProgram="$appBundleMacOSDir/$cmdProgram"
      else
        mapfile -t -d $'\0' findResult < <(find "$appBundleMacOSDir" -maxdepth 1 -type f -a -perm -0100 -print0)
        if [[ ${#findResult[@]} -eq 0 ]]; then
          echo "electronWrapHook: found no executable in '$appBundleMacOSDir'"
          exit 1
        elif [[ ${#findResult[@]} -gt 1 ]]; then
          echo "electronWrapHook: found multiple executables in '$appBundleMacOSDir':"
          echo "${findResult[*]}"
          echo "Please set 'electronWrapAppExecutableName' to disambiguate"
          exit 1
        else
          wrappedProgram="${findResult[0]}"
        fi
      fi
    fi

    local -a electronWrapperArgsArray=()
    concatTo electronWrapperArgsArray electronWrapperArgs

    mkdir -p "${!outputBin}/bin"
    makeWrapper "$wrappedProgram" "${!outputBin}/bin/${cmdProgram}" "${electronWrapperArgsArray[@]}"

    echo "electronWrapHook: wrapper running '$wrappedProgram' placed in '${!outputBin}/bin/$cmdProgram'"
    echo "electronWrapHook finished."
    return
  fi

  local -a electronWrapperArgsArray=(
    # Actually launch the Electron program
    "--add-flag" "$pathToWrap"
    # This is generally desired for `top` purposes, and node will
    # doesn't look adjacent to argv0, which is to say that it will
    # not look around the argv0 argument for other executables or files.
    "--inherit-argv0"
    # Tell Electron that it is being used in production regardless of how it was built
    # electron-is-dev also supports this var.
    "--set-default" "ELECTRON_FORCE_IS_PACKAGED" "1"
    # TODO: Decide what to do exactly about Wayland flags
    # It seems sometime semi-recently chromium dropped the
    # WaylandWindowDecorations and WebRTCPipeWriteCapturer features.
    # It also looks like ime and text-input-version-3 are default as well.
    # Unsure when these flags were removed and defaulted, but we may be able to just drop them.
  )
  # Concat user args to the flags array
  concatTo electronWrapperArgsArray electronWrapperArgs

  # Create the output dir, and wrap the asar
  mkdir -p "${!outputBin}/bin"
  makeWrapper "@ELECTRON_PACKAGE@/bin/electron" "${!outputBin}/bin/${cmdProgram}" "${electronWrapperArgsArray[@]}"

  echo "electronWrapHook: wrapper running '$pathToWrap' placed in '${!outputBin}/bin/$cmdProgram'"

  echo "electronWrapHook finished."
}

postInstall+=(electronWrapHook)
