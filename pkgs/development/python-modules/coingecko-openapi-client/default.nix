{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  aiohttp,
  certifi,
  pluggy,
  py,
  python-dateutil,
  pytest-cov,
  pytestCheckHook,
  six,
  urllib3,
}:

buildPythonPackage rec {
  pname = "coingecko-openapi-client";
  version = "1.4.0";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "Drakkar-Software";
    repo = "coingecko-openapi-clients";
    rev = "bb7dfbfb94e3907f288d3c6de593349fc7f767b7";
    hash = "sha256-D6m9CQRnT8urMejX5SS5/vPQr/99S7RpBLK8GxLqrME=";
  };

  sourceRoot = "${src.name}/client/python";

  # The generated client eagerly creates an aiohttp session during object
  # construction, but newer aiohttp requires a running event loop for that.
  # Patch it to create the session lazily so the upstream stub tests can
  # instantiate API classes during setUp.
  postPatch = ''
    python - <<'PY'
    from pathlib import Path

    path = Path("coingecko_openapi_client/rest.py")
    text = path.read_text()
    old = """class RESTClientObject(object):\n\n    def __init__(self, configuration, pools_size=4, maxsize=4):\n        # maxsize is number of requests to host that are allowed in parallel\n        # ca_certs vs cert_file vs key_file\n        # http://stackoverflow.com/a/23957365/2985775\n\n        # ca_certs\n        if configuration.ssl_ca_cert:\n            ca_certs = configuration.ssl_ca_cert\n        else:\n            # if not set certificate file, use Mozilla's root certificates.\n            ca_certs = certifi.where()\n\n        ssl_context = ssl.create_default_context(cafile=ca_certs)\n        if configuration.cert_file:\n            ssl_context.load_cert_chain(\n                configuration.cert_file, keyfile=configuration.key_file\n            )\n\n        connector = aiohttp.TCPConnector(\n            limit=maxsize,\n            ssl_context=ssl_context,\n            verify_ssl=configuration.verify_ssl\n        )\n\n        # https pool manager\n        if configuration.proxy:\n            self.pool_manager = aiohttp.ClientSession(\n                connector=connector,\n                proxy=configuration.proxy\n            )\n        else:\n            self.pool_manager = aiohttp.ClientSession(\n                connector=connector\n            )\n"""
    new = """class RESTClientObject(object):\n\n    def __init__(self, configuration, pools_size=4, maxsize=4):\n        # maxsize is number of requests to host that are allowed in parallel\n        self.configuration = configuration\n        self.maxsize = maxsize\n        self.pool_manager = None\n\n    def _build_pool_manager(self):\n        configuration = self.configuration\n\n        # ca_certs vs cert_file vs key_file\n        # http://stackoverflow.com/a/23957365/2985775\n        if configuration.ssl_ca_cert:\n            ca_certs = configuration.ssl_ca_cert\n        else:\n            # if not set certificate file, use Mozilla's root certificates.\n            ca_certs = certifi.where()\n\n        ssl_context = ssl.create_default_context(cafile=ca_certs)\n        if configuration.cert_file:\n            ssl_context.load_cert_chain(\n                configuration.cert_file, keyfile=configuration.key_file\n            )\n\n        connector = aiohttp.TCPConnector(\n            limit=self.maxsize,\n            ssl=ssl_context if configuration.verify_ssl else False,\n        )\n\n        if configuration.proxy:\n            return aiohttp.ClientSession(\n                connector=connector,\n                proxy=configuration.proxy\n            )\n\n        return aiohttp.ClientSession(connector=connector)\n"""
    if old not in text:
        raise SystemExit("expected RESTClientObject block not found")
    text = text.replace(old, new)

    old = """        method = method.upper()\n        assert method in ['GET', 'HEAD', 'DELETE', 'POST', 'PUT',\n                          'PATCH', 'OPTIONS']\n"""
    new = """        method = method.upper()\n        assert method in ['GET', 'HEAD', 'DELETE', 'POST', 'PUT',\n                          'PATCH', 'OPTIONS']\n\n        if self.pool_manager is None or self.pool_manager.closed:\n            self.pool_manager = self._build_pool_manager()\n"""
    if old not in text:
        raise SystemExit("expected request prelude not found")
    text = text.replace(old, new)

    path.write_text(text)
    PY
  '';

  dependencies = [
    aiohttp
    certifi
    python-dateutil
    six
    urllib3
  ];

  nativeCheckInputs = [
    pluggy
    py
    pytest-cov
    pytestCheckHook
  ];

  pytestFlagsArray = [ "test" ];

  pythonImportsCheck = [ "coingecko_openapi_client" ];

  meta = {
    description = "CoinGecko API V3 client";
    homepage = "https://github.com/Drakkar-Software/coingecko-openapi-clients";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
}
