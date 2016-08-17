require './env'
express = require('express')
request = require('superagent')
cache = new(require('./cache'))

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

route.get '/', (req, res, next) ->
	url = req.query.url
	format = req.query.format
	return next("Must specify 'url'") unless url
	return next("Must specify 'format'") unless format
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
				'url': url
				'sessionid': process.env.ZTS_SESSION
			.end (err, resp) ->
				doiMode = format is 'doi'
				if err
					console.error "/web threw", err
					return cache.put url, format, 500, 'text/plain', err.toString(), -> next(err)
				if doiMode
					format = 'ris'
				request
					.post("#{process.env.ZTS_URI}/export?format=#{format}")
					.buffer(true)
					.send(resp.body[0])
					.end (err, resp) ->
						if err
							console.error "/export threw", err
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
