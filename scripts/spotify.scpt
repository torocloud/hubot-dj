(**
 * current_song.scpt
 * Original Author: David van Leeuwen
 * - https://github.com/davidvanleeuwen
 * - http://davidvanleeuwen.nl/
 * - https://github.com/davidvanleeuwen/hubot-spotify/blob/master/current_song.scpt
 *)

on run
  set info to ""
  tell application "System Events"
    set num to count (every process whose name is "Spotify")
  end tell
  if num > 0 then
    tell application "Spotify"
      if player state is playing then
        set who to artist of current track
        set what to name of current track
        set onwhat to album of current track
        set info to "“" & what & "”" & " by " & who & " " & "from " & onwhat
      end if
    end tell
  end if
  return info
end run
