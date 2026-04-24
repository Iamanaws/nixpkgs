{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pdm-backend,
  psycopg,
  python-dateutil,
  pyyaml,
  sqlalchemy,
  typer,
  websockets,
}:

buildPythonPackage rec {
  pname = "dbos";
  version = "2.19.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "dbos-inc";
    repo = "dbos-transact-py";
    tag = version;
    hash = "sha256-By+8OEmod9/o04kIZtd9YciNqF0iOhTn4DooXnVJyVQ=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail "typer-slim" "typer"
  '';

  build-system = [ pdm-backend ];

  dependencies = [
    pyyaml
    python-dateutil
    psycopg
    websockets
    typer
    sqlalchemy
  ];

  pythonImportsCheck = [ "dbos" ];

  meta = {
    description = "Ultra-lightweight durable execution in Python";
    homepage = "https://docs.dbos.dev/";
    changelog = "https://github.com/dbos-inc/dbos-transact-py/releases/tag/${src.tag}";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
}
