#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix curl jq common-updater-scripts

set -eou pipefail

latestVersion=$(curl -s https://api.github.com/repos/mongodb-js/compass/releases/latest | jq -r .tag_name | sed 's/^v//')

if [[ "$latestVersion" == "$UPDATE_NIX_OLD_VERSION" ]]; then
  echo "mongodb-compass is already up-to-date: $latestVersion"
  exit 0
fi

update-source-version mongodb-compass "$latestVersion"

srcUrl="https://github.com/mongodb-js/compass/archive/refs/tags/v${latestVersion}.tar.gz"
srcHash=$(nix --extra-experimental-features nix-command hash convert --to sri --hash-algo sha256 "$(nix-prefetch-url --unpack "$srcUrl")")
update-source-version mongodb-compass "$latestVersion" "$srcHash" --ignore-same-version --ignore-same-hash
