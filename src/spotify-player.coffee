##
# spotify-player.coffee
# Original Author: David van Leeuwen
#  - https://github.com/davidvanleeuwen
#  - http://davidvanleeuwen.nl/
#  - https://github.com/davidvanleeuwen/hubot-spotify/blob/master/current_song.scpt
#

{join} = require 'path'
script = "#{join process.cwd(), 'node_modules/hubot-dj/scripts/spotify.scpt'}"

rq = require 'request'
sh = require 'sh'

module.exports = (robot) ->
  options = volume: 100

  # Spotify Player: Toggle Play/Pause Controls
  robot.respond /toggle$/i, (msg) ->
    msg.send "Okay, toggling play/pause in Spotify"
    sh('osascript -e \'tell app "Spotify" to playpause\'')

  robot.respond /play$/i, (msg) ->
    msg.send "Playing the current song in Spotify"
    sh('osascript -e \'tell app "Spotify" to playpause\'')

  robot.respond /(pause|stop)$/i, (msg) ->
    msg.send "Pausing the current song in Spotify"
    sh('osascript -e \'tell app "Spotify" to playpause\'')

  # Spotify PLayer:  Play Next Tracks
  robot.respond /(next|play next|play the next song)$/i, (msg) ->
    sh('osascript -e \'tell app "Spotify" to next track\'')
    song = sh("osascript #{script}")
    song.result (obj) ->
      msg.send "And now I'm playing "+ obj

  # Spotify Player: Play Previous Tracks
  robot.respond /(previous|prev|play previous|play the previous song)$/i, (msg) ->
    sh('osascript -e \'tell app "Spotify" to previous track\'')
    song = sh("osascript #{script}")
    song.result (obj) ->
      msg.send "Playing this song again: "+ obj

  # Spotify Player: Volume Controls
  robot.respond /volume ((\d{1,2})|up|down)$/i, (msg) ->
    volume = msg.match[1]
    switch volume
      when "up"
        if options.volume < 100
          options.volume+=10
          msg.send "Louder, louder!"
      when "down"
        if options.volume > 0
          options.volume-=10
          msg.send "Ah, I was trying to say it, but nobody could hear me. Oh wait, I don't have a voice"
      else
        if volume < (options.volume/10)
          msg.send "Yes, this is too loud for me"
        else
          msg.send "Turning up the volume! w00t"
        options.volume = Math.round(volume)*10 if volume <= 100

    sh('osascript -e \'tell application "Spotify" to set sound volume to '+options.volume+'\'')

  robot.respond /mute$/i, (msg) ->
    if options.muted
      sh('osascript -e \'tell application "Spotify" to set sound volume to '+options.volume+'\'')
      msg.send "That was a quiet moment"
    else
      sh('osascript -e \'tell application "Spotify" to set sound volume to 0\'')
      msg.send "Si
      \
      lence"
    options.muted = !options.muted

  robot.respond /unmute$/i, (msg) ->
    if options.muted
      sh('osascript -e \'tell application "Spotify" to set sound volume to '+options.volume+'\'')
      msg.send "That was a quiet moment"

  # show what song I'm currently playing
  robot.respond /(current|song|track|current song|current track)$/i, (msg) ->
    song = sh("osascript #{script}")
    song.result (obj) ->
      msg.reply "The current song I'm playing is "+ obj
