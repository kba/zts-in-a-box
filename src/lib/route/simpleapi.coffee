require '../env'
express = require('express')
request = require('superagent')
cache = new(require('../cache'))

module.exports = route = new express.Router()

route.get '/cache', (req, res, next) ->
	cache.size (err, cacheSize) ->
		return next err if err
		res.statusCode = 200
		res.set 'content-type', 'text/plain'
		res.send "#{cacheSize}"

route.delete '/cache', (req, res, next) ->
	cache.clear (err, nrRemoved) ->
		return next err if err
		res.statusCode = 200
		res.set 'content-type', 'text/plain'
		res.send "#{nrRemoved}"

_zoteroExport = (sessionid, data, url, format, res, next) ->
	doiMode = format is 'doi'
	if doiMode
		format = 'ris'
	request
		.post("#{process.env.ZTS_URI}/export?format=#{format}")
		.buffer(true)
		.send(data)
		.end (err, resp) ->
			if err
				console.error "[#{sessionid}] /export threw #{err}"
				return cache.put url, format, 500, 'text/plain', err.toString(), -> next(err)
			contentType = resp.headers['content-type']
			console.log "Content Type: #{contentType}"
			statusCode = resp.statusCode
			text = resp.text
			if doiMode
				format = 'doi'
				contentType = 'text/x-doi'
				m = resp.text.match(/DO\s+-\s+(.*)/)
				if m
					text = m[1]
				else
					statusCode = 404
			cache.put url, format, statusCode, contentType, text, (err) ->
				return next err if err
				res.statusCode = statusCode
				res.set 'content-type', contentType
				res.send text

route.get '/', (req, res, next) ->
	url = req.query.url
	format = req.query.format
	return next("Must specify 'url'") unless url
	return next("Must specify 'format'") unless format
	sessionid = req.query.sessionid or Math.random().toString(36).slice(2)
	cache.get url, format, (err, statusCode, contentType, text) ->
		unless err
			console.log "Found in cache: ", [statusCode, contentType, text.length]
			res.statusCode = statusCode
			res.header 'content-type', contentType
			return res.send text
		console.log "Not in cache, passing to zotero translation server"
		request
			.post("#{process.env.ZTS_URI}/web")
			.send
				url: url
				sessionid: sessionid
			.end (err, resp) ->
				unless err
					return _zoteroExport sessionid, resp.body[0], url, format, res, next
				if resp.statusCode != 300
					console.error "[#{sessionid}]/web threw #{err}"
					return cache.put url, format, resp.statusCode, 'text/plain', err.toString(), -> next(err)
				choices = resp.body
				console.log "Multiple choices: ", choices
				if Object.keys(choices).length != 1
					return cache.put url, format, 300, 'text/plain', "Ambigious", -> next(err)
				request
					.post("#{process.env.ZTS_URI}/web")
					.send
						url: url
						sessionid: sessionid
						items: choices
					.end (err, resp) ->
						if err
							console.error "[#{sessionid}] /web threw #{err} for items #{choices}"
							return cache.put url, format, resp.statusCode, 'text/plain', "Unresolvable", -> next(err)
						return _zoteroExport sessionid, resp.body[0], url, format, res, next
