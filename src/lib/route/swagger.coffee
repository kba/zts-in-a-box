require '../env'
Fs = require 'fs'
Mustache = require 'mustache'
RootPath = require 'app-root-path'
{TRAF} = require 'traf'

swaggerString = Mustache.render(Fs.readFileSync("#{RootPath}/zts.swagger.yml", encoding:'utf-8'), process.env)
swaggerObject = TRAF.parseSync swaggerString, {format: 'YAML'}
swaggerYAML = TRAF.stringifySync swaggerObject, {format: 'YAML'}
swaggerJSON = TRAF.stringifySync swaggerObject, {format: 'JSON'}

module.exports = route = new require('express').Router()

route.get '/yaml', (req, res, next) ->
	res.header 'content-type', 'text/yaml'
	res.send swaggerYAML

route.get '/json', (req, res, next) ->
	res.header 'content-type', 'application/json'
	res.send swaggerJSON
