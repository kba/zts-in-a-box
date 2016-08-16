require './env'
express = require('express')
proxy = require('http-proxy-middleware')
morgan = require('morgan')('combined')

app = new express()

app.use morgan

app.use process.env.SWAGGER_BASEPATH, require('./swagger')
app.use process.env.SIMPLEAPI_BASEPATH, require('./simpleapi')
app.use process.env.ZTS_BASEPATH, proxy(
	target: 'http://zts-app:1969'
	pathRewrite: "#{process.env.ZTS_BASEPATH}": '/'
	changeOrigin: false
)
app.use process.env.BASEPATH, proxy(target: 'http://zts-swagger-app:8888/swagger-ui', changeOrigin: true)

app.use (err, req, res, next) ->
	console.log 'Failed request', err
	res.status(401).send err
	return

app.listen 1970, (err) ->
	if err
		console.error err
		process.exit 100
	console.log "Started server on port 1970"

