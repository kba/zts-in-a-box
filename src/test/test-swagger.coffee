Test = require 'tape'
Supertest = require 'supertest'
Superagent = require 'superagent'
Util = require 'util'
AJV = new(require 'ajv')(
	allErrors: true
	verbose:true
)
process.env.HOST_AND_PORT = 'example.org:32'
process.env.BASEPATH = '/'

app = require('express')()
app.use(require '../lib/swagger')
swaggerSchema = 'https://rawgit.com/OAI/OpenAPI-Specification/master/schemas/v2.0/schema.json'

Test 'Valid swagger', (t) ->
	Supertest(app)
		.get('/json')
		.expect('Content-Type', /application\/json/)
		.expect(200)
		.end (err, res) ->
			t.ok not err, "HTTP headers as expected"
			json = res.body
			Superagent.get(swaggerSchema).end (err, res) ->
				schema = res.body
				AJV.validate schema, json
				t.ok not AJV.errors, "No validation erros"
				if AJV.errors
					console.log Util.inspect AJV.errors, colors:true, depth: 4
				t.end()
