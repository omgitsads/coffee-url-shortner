redis = require 'redis'
client = redis.createClient()

#### Shortner class
class Shortner
  # Setup the class with an array of valid chars.
  # You can add more to this if you want extra chars
  # but i dont think i'll run out of combinations
  constructor: ->
    @chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.split("")

  #### Create
  # Create a new short code based on a url
  create: (url, callback) ->
    # Check for the url in Redis
    client.get "shortner:url:#{url}", (err, code) =>
      # If we have the url in the database, the code
      # will be returned, so trigger the callback
      # specified.
      if code?
        callback code
      # If we dont, then encode the url and pass the 
      # callback through.
      else
        @encode url, callback

  #### Lookup
  # Lookup a url based on a code
  lookup: (code, callback) ->
    # Find the code in redis
    client.get "shortner:code:#{code}", (err, url) ->
      # Trigger the callback, if url is null, you will
      # have to handle this in your application code.
      callback url

  #### Encode
  # Encode a url to a short url. (not really encoding)
  encode: (url, callback) ->
    # Generate a seed code
    seed = @seed()
    # Try and find that seed in the Redis DB
    client.get "shortner:code:#{seed}", (err, code) =>
      # If the code is there, then we need to generate
      # another seed, so call ourselves again, repeat
      # until we find a code that doesnt exist.
      if code?
        @encode url, callback
      # If we cant find the code, then we can use it.
      else
        # Start a Redis Multi Transaction
        multi = client.multi()

        # Add the url -> seed record
        multi.set "shortner:url:#{url}", seed

        # Add the seed -> url record
        multi.set "shortner:code:#{seed}", url

        # Push the url to the list of created urls
        multi.lpush "shortner:urls", url

        # Execute all the requests
        multi.exec (err, result) ->
          # Execute the callback
          callback seed

  #### Seed
  # Generate a short code
  seed: ->
    # Start off with an empty string
    seed = ""
    # Loop 4 times
    for num in [1..4]
      # Grab a random character from the @chars array
      seed += @chars[Math.ceil(Math.random()*@chars.length)]
    # Return the generated Seed
    return seed

module.exports = new Shortner
