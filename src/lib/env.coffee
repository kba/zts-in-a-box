process.env.HOST_AND_PORT      or= "localhost:1970"
process.env.BASEPATH           or= '/'
process.env.SWAGGER_BASEPATH   or= '/swagger'
process.env.SWAGGER_URI        or= 'http://localhost:8888'
process.env.ZTS_BASEPATH       or= '/zts'
process.env.ZTS_SESSION        or= 'foo-123'
process.env.ZTS_URI            or= 'http://localhost:1969'
process.env.SIMPLEAPI_BASEPATH or= '/simple'
if 'SIMPLEAPI_CACHE_ENABLED' of process.env and process.env.SIMPLEAPI_CACHE_ENABLED in ['true', 1, true]
	process.env.SIMPLEAPI_CACHE_ENABLED = true
# XXX hardcoded
process.env.CACHE_ENABLED = true
