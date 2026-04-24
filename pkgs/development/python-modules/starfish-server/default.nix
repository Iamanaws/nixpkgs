{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
  fastapi,
  pydantic,
  cryptography,
  uvicorn,
  httpx,
  aiofiles,
  jsonschema,
  starfish-protocol,
  aiobotocore,
  pytestCheckHook,
  pytest-asyncio,
  respx,
}:

buildPythonPackage rec {
  pname = "starfish-server";
  version = "1.1.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Drakkar-Software";
    repo = "Starfish";
    tag = "v${version}";
    hash = "sha256-oTv/u/3OEy8GttjkmTpRN0b6Aiuua3VZiBXBlDAvGT8=";
  };

  sourceRoot = "${src.name}/packages/python/server";

  build-system = [
    setuptools
    wheel
  ];

  dependencies = [
    fastapi
    pydantic
    cryptography
    uvicorn
    httpx
    aiofiles
    jsonschema
    starfish-protocol
  ];

  optional-dependencies = {
    s3 = [ aiobotocore ];
    dev = [
      pytestCheckHook
      pytest-asyncio
      respx
    ];
  };

  nativeCheckInputs = optional-dependencies.dev;

  pythonImportsCheck = [ "starfish_server" ];

  meta = {
    description = "Python server for the Starfish sync protocol";
    homepage = "https://github.com/Drakkar-Software/Starfish";
    changelog = "https://github.com/Drakkar-Software/Starfish/releases/tag/${src.tag}";
    license = lib.licenses.unfree;
    maintainers = [ ];
  };
}
