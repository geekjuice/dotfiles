#!/bin/bash

#########################################
# Music Player Command Line Control v1.0
# written by David Schlosnagle
# created 2001.11.08
# edit    2013.11.09 Nicholas Hwang
#########################################

# TODO:
#   - Display other info as well i.e. album
#   - Add aliases.itunes shortcuts

# Color Outputs [Optional]
red='\e[0;31m'
green='\e[0;32m'
yellow='\e[0;33m'
blue='\e[0;34m'
reset='\e[0m'
recho () { printf "${red}$1${reset}\n"; }
gecho () { printf "${green}$1${reset}\n"; }
yecho () { printf "${yellow}$1${reset}\n"; }
becho () { printf "${blue}$1${reset}\n"; }
wecho () { printf "$1\n"; }

APP="$1"

showHelp () {
    header="$APP Command Line Interface"
    headerLength=${#header}
    eval printf "=%.0s" {1..$headerLength}
    echo;
    echo $header
    eval printf "=%.0s" {1..$headerLength}
    echo;

    echo "Usage: `basename $0` <option>";
    echo;
    echo "Options:";
    echo " open         = Open $APP";
    echo " status       = Shows $APP' status, current artist and track";
    echo " play         = Start playing $APP";
    echo " pause        = Pause $APP";
    echo " next         = Go to the next track";
    echo " prev         = Go to the previous track";
    echo " mute         = Mute $APP' volume";
    echo " unmute       = Unmute $APP' volume";
    echo " vol up       = Increase $APP' volume by 10%";
    echo " vol down     = Increase $APP' volume by 10%";
    echo " vol #        = Set $APP' volume to # [0-100]";
    echo " stop         = Stop $APP";
    echo " playlist     = Show playlists saved in $APP";
    echo " tracks       = Show tracks for current or given playlist";
    echo " shuffle      = Shuffle current playlist";
    echo " noshuffle    = Do not shuffle current playlist";
    echo " quit         = Quit $APP";
}

appRunning () {
    echo `osascript -e 'tell application "System Events" to (name of processes) contains "'$APP'"'`
}

currentTrack () {
    running=$(appRunning)
    if [[ $running = "true" ]]; then
        state=`osascript -e 'tell application "'$APP'" to player state as string'`;
        if [[ $state = "playing" ]]; then
            artist=`osascript -e 'tell application "'$APP'" to artist of current track as string'`;
            track=`osascript -e 'tell application "'$APP'" to name of current track as string'`;
            album=`osascript -e 'tell application "'$APP'" to album of current track as string'`;
            echo "Current track: $artist [$album] - $track"
        fi
    fi
}

case $# in
    0)
        echo "Please enter application name..."
        exit 1;;
    1)
        current=$(currentTrack);
        if [[ $current = '' ]]; then
            showHelp;
        else
            echo $current
        fi
esac

while [[ $# -gt 1 ]]; do
    arg=$2;
    case $arg in
        "status" )
            current=$(currentTrack);
            if [[ $current = '' ]]; then
                echo "$APP is currently stopped";
            else
                echo "$APP is currently playing";
                echo $current
            fi
            break ;;

        "play" )
            echo "Playing $APP";
            osascript -e 'tell application "'$APP'" to play';
            currentTrack;
            break ;;

        "pause" )
            echo "Pausing $APP";
            osascript -e 'tell application "'$APP'" to pause';
            break ;;

        "next" )
            echo "Going to next track" ;
            osascript -e 'tell application "'$APP'" to next track';
            currentTrack;
            break ;;

        "prev" )
            echo "Going to previous track";
            osascript -e 'tell application "'$APP'" to previous track';
            currentTrack;
            break ;;

        "mute" )
            echo "Muting $APP volume level";
            osascript -e 'tell application "'$APP'" to set mute to true';
            break ;;

        "unmute" )
            echo "Unmuting $APP volume level";
            osascript -e 'tell application "'$APP'" to set mute to false';
            break ;;

        "vol" )
            vol=`osascript -e 'tell application "'$APP'" to sound volume as integer'`;
            if [[ $3 = '' ]]; then
                echo "Current volume is $vol%"
                break
            else
                echo "Changing $APP volume level";
                if [[ $3 = "up" ]]; then
                    newvol=$(( vol+10 ));
                elif [[ $3 = "down" ]]; then
                    newvol=$(( vol-10 ));
                elif [[ $3 -gt 0 ]]; then
                    newvol=$3;
                fi
            fi
            osascript -e 'tell application "'$APP'" to set sound volume to '$newvol;
            break ;;

        "stop" )
            echo "Stopping $APP";
            osascript -e 'tell application "'$APP'" to stop';
            break ;;

        "open" )
            echo "Opening $APP";
            osascript -e 'tell application "'$APP'" to activate';
            exit 1 ;;

        "quit" )
            echo "Quitting $APP";
            osascript -e 'tell application "'$APP'" to quit';
            exit 1 ;;

        "playlist" )
            if [[ -n "$3" ]]; then
                echo "Changing $APP playlists to '$3'";
                osascript -e 'tell application "'$APP'"' -e "set new_playlist to \"$3\" as string" -e "play playlist new_playlist" -e "end tell";
                break ;
            else
                echo "Playlists:";
                osascript -e 'tell application "'$APP'"' -e "set allPlaylists to (get name of every playlist)" -e "end tell";
                break;
            fi
            break;;

        "shuffle" )
            echo "Shuffle is ON";
            osascript -e 'tell application "'$APP'" to set shuffle of current playlist to 1';
            break ;;

        "noshuffle" )
            echo "Shuffle is OFF";
            osascript -e 'tell application "'$APP'" to set shuffle of current playlist to 0';
            break ;;

        "tracks" )
            if [[ -n "$3" ]]; then
                osascript -e 'tell application "'$APP'"' -e "set new_playlist to \"$3\" as string" -e " get name of every track in playlist new_playlist" -e "end tell";
                break;
            fi
            osascript -e 'tell application "'$APP'" to get name of every track in current playlist';
            break ;;

        "help" | * )
            showHelp;
            break ;;

    esac
done
