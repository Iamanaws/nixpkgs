{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  cython,
  numpy,
  pytestCheckHook,
  setuptools,
  wheel,
}:

buildPythonPackage rec {
  pname = "octobot-tulipy";
  version = "0.4.10";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Drakkar-Software";
    repo = "tulipy";
    tag = version;
    hash = "sha256-bZb2AE7G7KMgS7LKZqrw6JIN+sEcIHHd17OWQlrTEoI=";
  };

  build-system = [
    cython
    numpy
    setuptools
    wheel
  ];

  # Cython 3 and current toolchains enforce the tulip indicator API's const
  # input pointers, so patch the generated binding source to match the header.
  postPatch = ''
    substituteInPlace tulipy/lib/__init__.pyx \
      --replace-fail \
        "cdef ti.TI_REAL * c_inputs[ti.TI_MAXINDPARAMS]" \
        "cdef const ti.TI_REAL * c_inputs[ti.TI_MAXINDPARAMS]"
  '';

  dependencies = [ numpy ];

  nativeCheckInputs = [ pytestCheckHook ];

  # Force the tests to import the installed extension module instead of the
  # source tree package, which has no built `tulipy.lib` yet.
  preCheck = ''
    mv tulipy tulipy-src
  '';

  pytestFlagsArray = [ "tests/test.py" ];

  pythonImportsCheck = [ "tulipy" ];

  meta = {
    description = "Financial technical analysis indicator library";
    homepage = "https://github.com/Drakkar-Software/tulipy";
    license = lib.licenses.lgpl3Only;
    maintainers = [ ];
  };
}
