require './env'
express = require('express')
request = require('superagent')
cache = {}

module.exports = route = new express.Router()

route.get '/restart', ->
	console.log 'Deliberately Exiting with code 10'
	process.exit 10

route.get '/', (req, res, next) ->
	url = req.query.url
	if !url
		return next('ERROR: Must specify url')
	format = req.query.format or 'ris'
	cache[url] = cache[url] or {}
	if process.env.SIMPLEAPI_CACHE_ENABLED and cache[url] and cache[url][format]
		cached = cache[url][format]
		console.log 'In cache:  ' + format + ' / ' + url
		res.statusCode = cached[0]
		res.set 'Content-Type', cached[1]
		res.send cached[2]
		return
	console.log 'Passing to zotero translation server: ' + url
	request.post("#{process.env.ZTS_URI}/web").send(
		'url': url
		'sessionid': process.env.ZTS_SESSION).end (err, resp) ->
		doiMode = format == 'doi'
		if err
			cache[url][if doiMode then 'doi' else format] = [
				500
				'text/plain'
				err.toString()
			]
			return next(err)
		console.log '=============================================================================='
		console.log resp.body
		console.log '=============================================================================='
		if doiMode
			format = 'ris'
		request.post("#{process.env.ZTS_URI}/export?format=#{format}").buffer(true).send(resp.body).end (err, resp) ->
			`var cached`
			if err
				cache[url][if doiMode then 'doi' else format] = [
					500
					'text/plain'
					err.toString()
				]
				return next(err)
			contentType = if doiMode then 'text/plain' else resp.headers['content-type']
			statusCode = resp.statusCode
			text = resp.text
			if doiMode
				m = resp.text.match(/DO\s+-\s+(.*)/)
				if !m
					statusCode = 404
				else
					text = m[1]
				format = 'doi'
			cached = cache[url][format] = [
				statusCode
				contentType
				text
			]
			res.statusCode = cached[0]
			res.set 'Content-Type', cached[1]
			res.send cached[2]
			return
		return
	return
