{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  aiohttp,
  requests,
}:

buildPythonPackage rec {
  pname = "simplifiedpytrends";
  version = "1.1.2";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "Drakkar-Software";
    repo = "simplifiedpytrends";
    tag = version;
    hash = "sha256-UDJpH1NbarCbyKRJBMZ6+h4W9kxG6CpCIeXyRoAf4+M=";
  };

  dependencies = [
    aiohttp
    requests
  ];

  pythonImportsCheck = [ "simplifiedpytrends" ];

  meta = {
    description = "Simplified pseudo API for Google Trends";
    homepage = "https://github.com/Drakkar-Software/simplifiedpytrends";
    license = lib.licenses.asl20;
    maintainers = [ ];
  };
}
