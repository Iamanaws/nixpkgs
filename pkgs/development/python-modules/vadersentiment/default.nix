{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  requests,
}:

buildPythonPackage {
  pname = "vaderSentiment";
  version = "3.3.2";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "cjhutto";
    repo = "vaderSentiment";
    rev = "0150f59077ad3b8d899eff5d4c9670747c2d54c2";
    hash = "sha256-uRSg/tuZgylH7G6LMUXDpRqXb54urk/aZRn094RhVEc=";
  };

  dependencies = [ requests ];

  pythonImportsCheck = [ "vaderSentiment" ];

  meta = {
    description = "Rule-based sentiment analysis tool for social media text";
    homepage = "https://github.com/cjhutto/vaderSentiment";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
}
