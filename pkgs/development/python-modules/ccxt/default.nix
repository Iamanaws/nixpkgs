{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  certifi,
  requests,
  cryptography,
  typing-extensions,
  aiohttp,
  aiodns,
  yarl,
  coincurve,
}:

buildPythonPackage (finalAttrs: {
  pname = "ccxt";
  version = "4.5.50";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "ccxt";
    repo = "ccxt";
    tag = "v${finalAttrs.version}";
    hash = "sha256-YUwY6k0A+ILiKzUdDba3Sv+8Ly2xdnkld3OOPiVUGss=";
  };

  sourceRoot = "${finalAttrs.src.name}/python";

  nativeBuildInputs = [ setuptools ];

  dependencies = [
    certifi
    requests
    cryptography
    typing-extensions
    aiohttp
    aiodns
    yarl
    coincurve
  ];

  # has no tests
  doCheck = false;

  pythonImportsCheck = [
    "ccxt"
    "ccxt.async_support"
  ];

  meta = {
    description = "Cryptocurrency trading API with support for many exchanges";
    homepage = "https://github.com/ccxt/ccxt";
    changelog = "https://github.com/ccxt/ccxt/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
})
