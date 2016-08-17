require './env'
Fs = require 'fs'
Mkdirp = require 'mkdirp'
Glob = require 'glob'
Async = require 'async'

# Structure:
# /TMPDIR/http___somesite.com_foo.ris => '...'
# /TMPDIR/http___somesite.com_foo.ris.statusCode => '200'
# /TMPDIR/http___somesite.com_foo.ris.contentType => 'text/ris'

module.exports = class Cache

	constructor: ->
		@cacheDir = process.env.CACHE_DIR
		Mkdirp.sync @cacheDir

	@cleanString : (strs...) ->
		return strs.map((str) -> str.replace(/[^A-Za-z0-9]/g, '')).join('.')

	size: (cb) ->
		Glob "#{@cacheDir}/*", (err, files) ->
			return cb(err) if err
			return cb null, files.length / 3

	clear: (cb) ->
		Glob "#{@cacheDir}/*", (err, files) ->
			return cb(err) if err
			Async.each files, Fs.unlink, (err) ->
				return cb err, files.length / 3

	put : (url, format, statusCode, contentType, text, cb) ->
		unless process.env.SIMPLEAPI_CACHE_ENABLED
			console.log "Cache disabled, put always succeeds"
			return cb null
		key = Cache.cleanString url, format
		console.log "Caching at #{key}"
		Fs.writeFile "#{@cacheDir}/#{key}", text, {encoding: 'utf-8'}, (err) =>
			return cb err if err
			Fs.writeFile "#{@cacheDir}/#{key}.statusCode", statusCode, {encoding: 'utf-8'}, (err) =>
				return cb err if err
				Fs.writeFile "#{@cacheDir}/#{key}.contentType", contentType, {encoding: 'utf-8'}, cb

	get : (url, format, cb) ->
		return cb new Error("Cache disabled") unless process.env.SIMPLEAPI_CACHE_ENABLED
		key = Cache.cleanString url, format
		Fs.readFile "#{@cacheDir}/#{key}", {encoding: 'utf-8'}, (err, text) =>
			return cb err if err
			console.log "Found cached: #{key}"
			Fs.readFile "#{@cacheDir}/#{key}.statusCode", {encoding: 'utf-8'}, (err, statusCode) =>
				return cb err if err
				Fs.readFile "#{@cacheDir}/#{key}.contentType", {encoding: 'utf-8'}, (err, contentType) ->
					return cb err, parseInt(statusCode), contentType, text

