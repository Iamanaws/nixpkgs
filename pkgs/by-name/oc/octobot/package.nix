{
  fetchFromGitHub,
  lib,
  python3Packages,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "octobot";
  version = "2.1.1";
  format = "setuptools";

  disabled = python3Packages.pythonOlder "3.13";

  src = fetchFromGitHub {
    owner = "Drakkar-Software";
    repo = "OctoBot";
    tag = finalAttrs.version;
    hash = "sha256-CeghTyZxZkTeQFhXwsylHvtIT+7IP19fBpokf/IE/iY=";
  };

  postPatch = ''
    # Upstream's setup.py only discovers packages from the repository root,
    # but OctoBot's internal Python packages live under packages/*/.
    for dir in packages/*/*; do
      [ -f "$dir/__init__.py" ] || continue

      name="$(basename "$dir")"
      case "$name" in
        tests|tests_additional)
          continue
          ;;
      esac

      ln -s "$dir" "$name"
    done
  '';

  propagatedBuildInputs = with python3Packages; [
    aiodns
    aiofiles
    aioboto3
    aiohttp
    aiosqlite
    asyncpraw
    cachetools
    certifi
    ccxt
    clickhouse-connect
    coingecko-openapi-client
    colorlog
    cryptography
    cython
    dbos
    email-validator
    fastapi
    flask
    flask-caching
    flask-compress
    flask-cors
    flask-login
    flask-socketio
    flask-wtf
    gevent
    gevent-websocket
    gmqtt
    jinja2
    jsonschema
    mcp
    numpy
    openai
    packaging
    passlib
    pgpy
    postgrest
    protobuf
    psutil
    pyarrow
    pydantic
    pyngrok
    python-dotenv
    python-multipart
    python-telegram-bot
    pyyaml
    requests
    sentry-sdk
    setuptools
    sortedcontainers
    standard-imghdr
    starfish-server
    starfish-sdk
    simplifiedpytrends
    supabase
    supabase-auth
    telethon
    tinydb
    octobot-tulipy
    urllib3
    vadersentiment
    web3
    websockets
    wtforms
  ];

  pythonImportsCheck = [ "octobot" ];

  meta = {
    changelog = "https://github.com/Drakkar-Software/OctoBot/blob/${finalAttrs.src.tag}/CHANGELOG.md";
    description = "Powerful cryptocurrency trading robot";
    homepage = "https://www.octobot.cloud/";
    license = lib.licenses.gpl3Plus;
    mainProgram = "OctoBot";
    maintainers = with lib.maintainers; [ ];
  };
})
