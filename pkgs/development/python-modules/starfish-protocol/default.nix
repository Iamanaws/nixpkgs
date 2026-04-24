{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
  cryptography,
  pytestCheckHook,
  pytest-asyncio,
}:

buildPythonPackage rec {
  pname = "starfish-protocol";
  version = "1.1.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Drakkar-Software";
    repo = "Starfish";
    tag = "v${version}";
    hash = "sha256-oTv/u/3OEy8GttjkmTpRN0b6Aiuua3VZiBXBlDAvGT8=";
  };

  sourceRoot = "${src.name}/packages/python/protocol";

  build-system = [
    setuptools
    wheel
  ];

  dependencies = [ cryptography ];

  optional-dependencies = {
    dev = [
      pytestCheckHook
      pytest-asyncio
    ];
  };

  nativeCheckInputs = optional-dependencies.dev;

  pythonImportsCheck = [ "starfish_protocol" ];

  meta = {
    description = "Shared protocol primitives for the Starfish sync protocol";
    homepage = "https://github.com/Drakkar-Software/Starfish";
    changelog = "https://github.com/Drakkar-Software/Starfish/releases/tag/${src.tag}";
    license = lib.licenses.unfree;
    maintainers = [ ];
  };
}
