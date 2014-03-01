#!/bin/bash

####################################
# iTunes Command Line Control v1.0
# written by David Schlosnagle
# created 2001.11.08
# edit    2013.11.09 Nicholas Hwang
####################################

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

showHelp () {
    echo "-----------------------------";
    echo "iTunes Command Line Interface";
    echo "-----------------------------";
    echo "Usage: `basename $0` <option>";
    echo;
    echo "Options:";
    echo " open         = Open iTunes";
    echo " status       = Shows iTunes' status, current artist and track";
    echo " play         = Start playing iTunes";
    echo " pause        = Pause iTunes";
    echo " next         = Go to the next track";
    echo " prev         = Go to the previous track";
    echo " mute         = Mute iTunes' volume";
    echo " unmute       = Unmute iTunes' volume";
    echo " vol up       = Increase iTunes' volume by 10%";
    echo " vol down     = Increase iTunes' volume by 10%";
    echo " vol #        = Set iTunes' volume to # [0-100]";
    echo " stop         = Stop iTunes";
    echo " playlist     = Show playlists saved in iTunes";
    echo " tracks       = Show tracks for current or given playlist";
    echo " shuffle      = Shuffle current playlist";
    echo " noshuffle    = Do not shuffle current playlist";
    echo " quit         = Quit iTunes";
}

iTunesRunning () {
    echo `osascript -e 'tell application "System Events" to (name of processes) contains "iTunes"'`
}

currentTrack () {
    if [[ $(iTunesRunning) = "true" ]]; then
        state=`osascript -e 'tell application "iTunes" to player state as string'`;
        if [[ $state = "playing" ]]; then
            artist=`osascript -e 'tell application "iTunes" to artist of current track as string'`;
            track=`osascript -e 'tell application "iTunes" to name of current track as string'`;
            album=`osascript -e 'tell application "iTunes" to album of current track as string'`;
            echo "Current track: $artist [$album] - $track"
        fi
    fi
}

if [[ $# = 0 ]]; then
    current=$(currentTrack);
    if [[ $current = '' ]]; then
        showHelp;
    else
        echo $current
    fi
fi

while [[ $# -gt 0 ]]; do
    arg=$1;
    case $arg in
        "status" )
            current=$(currentTrack);
            if [[ $current = '' ]]; then
                echo "iTunes is currently stopped";
            else
                echo "iTunes is currently playing";
                echo $current
            fi
            break ;;

        "play" )
            echo "Playing iTunes";
            osascript -e 'tell application "iTunes" to play';
            currentTrack;
            break ;;

        "pause" )
            echo "Pausing iTunes";
            osascript -e 'tell application "iTunes" to pause';
            break ;;

        "next" )
            echo "Going to next track" ;
            osascript -e 'tell application "iTunes" to next track';
            currentTrack;
            break ;;

        "prev" )
            echo "Going to previous track";
            osascript -e 'tell application "iTunes" to previous track';
            currentTrack;
            break ;;

        "mute" )
            echo "Muting iTunes volume level";
            osascript -e 'tell application "iTunes" to set mute to true';
            break ;;

        "unmute" )
            echo "Unmuting iTunes volume level";
            osascript -e 'tell application "iTunes" to set mute to false';
            break ;;

        "vol" )
            vol=`osascript -e 'tell application "iTunes" to sound volume as integer'`;
            if [[ $2 = '' ]]; then
                echo "Current volume is $vol%"
                break
            else
                echo "Changing iTunes volume level";
                if [[ $2 = "up" ]]; then
                    newvol=$(( vol+10 ));
                elif [[ $2 = "down" ]]; then
                    newvol=$(( vol-10 ));
                elif [[ $2 -gt 0 ]]; then
                    newvol=$2;
                fi
            fi
            osascript -e "tell application \"iTunes\" to set sound volume to $newvol";
            break ;;

        "stop" )
            echo "Stopping iTunes";
            osascript -e 'tell application "iTunes" to stop';
            break ;;

        "open" )
            echo "Opening iTunes";
            osascript -e 'tell application "iTunes" to activate';
            exit 1 ;;

        "quit" )
            echo "Quitting iTunes";
            osascript -e 'tell application "iTunes" to quit';
            exit 1 ;;

        "playlist" )
            if [[ -n "$2" ]]; then
                echo "Changing iTunes playlists to '$2'";
                osascript -e 'tell application "iTunes"' -e "set new_playlist to \"$2\" as string" -e "play playlist new_playlist" -e "end tell";
                break ;
            else
                # Show available iTunes playlists.
                echo "Playlists:";
                osascript -e 'tell application "iTunes"' -e "set allPlaylists to (get name of every playlist)" -e "end tell";
                break;
            fi
            break;;

        "shuffle" )
            echo "Shuffle is ON";
            osascript -e 'tell application "iTunes" to set shuffle of current playlist to 1';
            break ;;

        "noshuffle" )
            echo "Shuffle is OFF";
            osascript -e 'tell application "iTunes" to set shuffle of current playlist to 0';
            break ;;

        "tracks" )
            if [[ -n "$2" ]]; then
                osascript -e 'tell application "iTunes"' -e "set new_playlist to \"$2\" as string" -e " get name of every track in playlist new_playlist" -e "end tell";
                break;
            fi
            osascript -e 'tell application "iTunes" to get name of every track in current playlist';
            break ;;

        "help" | * )
            showHelp;
            break ;;

    esac
done
