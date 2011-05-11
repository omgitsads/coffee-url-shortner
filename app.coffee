# 
# Module dependencies.
#
express = require 'express'
app = module.exports = express.createServer()
shortner = require './lib/shortner'

# Configuration

app.configure () ->
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'ejs'
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static(__dirname + '/public')

app.configure 'development', () ->
  app.use express.errorHandler({ dumpExceptions: true, showStack: true })

app.configure 'production', () ->
  app.use express.errorHandler() 

# Routes

app.get '/', (req, res) ->
  res.render 'index', title: 'URL Shortner'

app.get '/:code', (req, res) ->
  shortner.lookup req.params.code, (url) ->
    if url?
      res.redirect url
    else
      res.send 'Code Unknown!', 404

app.post '/', (req, res) ->
  shortner.create req.body.url, (code) ->
    res.send short_url:"http://#{req.header "Host"}/#{code}", long_url: req.body.url, 201


# Only listen on $ node app.js

if not module.parent
  app.listen 3000
  console.log "Express server listening on port %d", app.address().port
