## Spotify Queue
# Authored by Pongstr Ordillo
#   - https://github.com/pongstr
#   - https://github.com/toro-io/hubot-dj
#

{join} = require 'path'
events = require 'events'

request = require 'request'
redis   = require 'redis'
shell   = require 'sh'
qs      = require 'querystring'

config =
  # auth_endpoint: 'https://damoocow.herokuapp.com/spotify/login'
  auth_endpoint: 'http://uikit.dev/spotify/login'
  spotify:
    baseurl: 'https://api.spotify.com/v1/'
    user_id: process.env.SPOTIFY_USER_ID
    client_id: process.env.SPOTIFY_CLIENT_ID
    client_secret: process.env.SPOTIFY_CLIENT_SECRET
    playlist: '18LoVT3QhcJY1AHVGay9uA'
    scope: [
      'user-follow-read'
      'user-library-read'
      'playlist-modify-public'
      'playlist-read-collaborative'
    ].join ' '
  redis:
    url: 'redis://127.0.0.1:16379/'

module.exports = (robot) ->
  # Event Listener to trigger Spotify Stuff
  spotify_event = new (events.EventEmitter)

  # Initialize Redis Client to Store Spotify Authentication Stuff
  spotify_redis = redis.createClient config.redis.url

  spotify_headers = (callback) ->
    spotify_redis.get 'hubot:spotify_auth', (err, content) ->
      content = JSON.parse content
      headers =
        "Authorization": "Bearer #{content.access_token}"
        "Content-Type": "application/json"
        "User-Agent": "@batibot via npm request"
      callback and callback(headers)

  # Hubot Respawned
  enter = [
    "What's up humanoids?! I've respawned, Let's take over the world.",
    "I'm your genie for today, you have three wishes I can fulfill.. Actually, just type in a command.",
    "Is anybody up? Let's brew some coffee.",
    "I'm built with CoffeeScript and Shell, I'm made for parties."
  ]

  # Hubot Night Mode
  leave = [
    "I need to relieve myself in the bathroom to reboot my awesomeness. Peace out!",
    "Rebooting to get my shit together, that was some party last night.",
    "Had chinese food last night, I need to quickly poop my guts out. See you in a bit."
  ]


  # Authenticate Spotify
  spotify_auth = (opts) ->
    request.get config.auth_endpoint, {
      qs: qs.stringify {
        client_id: config.spotify.client_id,
        client_secret: config.spotify.client_secret
      }
    }, (err, res, body) ->
      spotify_redis.set 'hubot:spotify_auth', body
      spotify_redis.end()

      spotify_event.removeListener 'hubot up', spotify_auth
      opts.msg.send "Spotify is authenticated, Waiting for your requests."

  # Spotify Search Listener
  spotify_search = (opts) ->
    req_opts =
      url: "#{config.spotify.baseurl}search"
      qs:
        q: "#{opts.query}"
        type: "track,artist"
        limit: 1
        offset: 0
        market: 'PH'

    spotify_headers (headers) ->
      req_opts.headers = headers
      request.get req_opts, (err, res, body) ->
        body = JSON.parse body
        song = if body.hasOwnProperty('tracks') then body.tracks.items[0] else null
        if song
          opts.msg.reply "I found #{song.external_urls.spotify}"
          opts.msg.send "/code \# To add this song to the Playlist: \n\n\> @#{opts.robot.name} spotify playlist add #{song.uri}"
        else
          opts.msg.send "/code Woops, we hit Status #{body.error.status} \n #{body.error.message}. Reloading Authentication to Spotify."
          spotify_event.on 'hubot up', spotify_auth
          spotify_event.emit 'hubot up',
            msg: msg
            robot: robot
        spotify_event.removeListener 'search', spotify_search
        spotify_redis.end()

  # Spotify Playlist Listener
  spotify_playlist = (opts) ->
    req_opts =
      url:"#{config.spotify.baseurl}users/#{config.spotify.user_id}/playlists/#{config.spotify.playlist}/tracks"
      qs:
        uris: "#{opts.query.trim()}"

    spotify_headers (headers) ->
      req_opts.headers = headers
      request.post req_opts, (err, res, body) ->
        console.log res
        body  = JSON.parse body
        queue = if body.hasOwnProperty('snapshot_id') then body else null

        if queue
          opts.msg.send "#{opts.query} has been added to #{config.spotify.playlist}"
        else
          opts.msg.send "Either the track is invalid or does not exists. Sorry."

        spotify_event.removeListener 'add-playlist', spotify_playlist
        spotify_redis.end()

  ##
  # @name Search Spotify
  # @desc listener function for searching songs
  #
  robot.respond /spotify-login/i, (msg) ->
    spotify_event.on 'hubot up', spotify_auth
    spotify_event.emit 'hubot up',
      msg: msg
      robot: robot

  ##
  # @name Spotify Commands
  # @keyword: spotify
  # @param: <playlist:search>
  # @actions: <add|remove|track|song>
  #
  robot.respond /spotify\s?(playlist|search)\:\s*?(add|remove|track|song)\s*?(.*)$/i, (msg) ->
    search = (action, message, robot) ->
      spotify_event.on 'search', spotify_search
      spotify_event.emit 'search',
        msg: message
        query: action.query
        robot: robot

    playlist = (action, message, robot) ->
      message.reply "You asked to #{action.exec} #{action.query} to #{action.keyword}"
      spotify_event.on 'add-playlist', spotify_playlist
      spotify_event.emit 'add-playlist',
        msg: message
        query: action.query
        robot: robot

    switch msg.match[1]
      when 'playlist'
        playlist {
          exec: msg.match[2]
          query: msg.match[3]
          keyword: msg.match[1]
        }, msg, robot
      when 'search'
        search {
          exec: msg.match[2]
          query: msg.match[3]
          keyword: msg.match[1]
        }, msg, robot
      else
        msg.reply "I'am up and running but I don't know what you would like to listen to."
