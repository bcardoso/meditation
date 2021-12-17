#!/bin/bash

# meditation.sh - 2010-2021
author="Bruno Cardoso <cardoso.bc@gmail.com>"
description="Flexible timer for meditation, working sessions & pomodoros."
version="0.8"


#===[ USER CONFIGS ]=========================================================#

BASEDIR="${HOME}/bin/meditation"

# default time intervals
DEFAULT_TIMER=25
DEFAULT_BREAK=5
DEFAULT_LONGBREAK=15

# pomodoro session
POMODOROS=7        # each POMODORO equals to $DEFAULT_TIMER + $DEFAULT_BREAK
LONGBREAK_AFTER=3  # number of default breaks before a long break

# a predefined time sequence
DEFAULT_SEQUENCE="23 5 23 5 23" # 79m focus work (~20% of an 8h work-day)

# interval labels
LABEL_WORKING="WORKING"
LABEL_BREAK="BREAK"
LABEL_LONGBREAK="LONG BREAK"

# player
#PLAYER="cvlc --play-and-exit"
#PLAYER="mplayer -really-quiet -volume 50"
PLAYER="mpv --really-quiet --vo=null --volume=50"

# sound bell
# bigbowl.mp3: http://www.freesound.org/samplesViewSingle.php?id=132
#SOUND="$BASEDIR/sound/bigbowl.mp3"
# singing-bell: https://www.freesound.org/people/ryancacophony/sounds/202017/
#SOUND="$BASEDIR/sound/singing-bell-hit2.mp3"
SOUND="$BASEDIR/sound/singing-bell-hit2-normalized.mp3"



#===[ FUNCTIONS ]============================================================#

show_help () {
    echo -e "$(basename $0) v$version\n$author\n\n$description\n"
    echo -e "\n USAGE:\n"
    echo -e "   $(basename $0) [OPTIONS] [<intervals>]"
    echo -e "\n OPTIONS:\n"
    grep ") \#" $0 | tr -s " " | sed -e 's/\t/\ /g;s/^ /\t-/g;s/)\ \#\#/\t/g'
    echo -e "\n EXAMPLES:\n"
    echo -e "   $(basename $0)          \tdefault interval is $DEFAULT_TIMER minutes"
    echo -e "   $(basename $0) 2 3 5    \tset timer to 2, 3 and 5 minutes"
    echo -e "   $(basename $0) 23/5     \tloop for 23 and 5 minutes (same as '-r 23 5')"
    echo -e "   $(basename $0) -nl 23/5 \tsame, with interval labels and notifications"
    echo -e "   $(basename $0) -p       \tstart a pomodoro session"
    echo -e "   $(basename $0) -s       \tpredefined interval sequence ('$DEFAULT_SEQUENCE')"
    echo
    exit
}

check_num () {
    [ $1 -gt 0 2> /dev/null ] && printf $1 || printf $2
}

plain_timer () {
    $NOTIFY && notify-send "$2 for $1 minutes... $3"
    printf "[$(date +%H:%M)"
    $LABELS && print_label "$2" "$3"
    printf "]\t$1 min...\n"
    sleep "$1"m
    $PLAY_SOUND && ($PLAYER $SOUND & 2> /dev/null)
}

countdown () {
    $NOTIFY && notify-send "$2 for $1 minutes... $3"
    clear
    echo
    $LABELS && print_label "$2" "$3"
    for j in $(eval echo {$1..00}) ; do
        for i in {59..00} ; do
            tput cup 3 4
            printf "$j:$i   "
            if $COUNTDOWN_FILE ; then
                printf "$2\n\n    $j:$i" > "$BASEDIR/countdown.txt"
            fi
            sleep 1
        done
    done
    echo
    $PLAY_SOUND && ($PLAYER $SOUND & 2> /dev/null)
}

run_timer () {
    min=$1
    if $COUNTDOWN_STDOUT ; then
        countdown $(( min - 1 )) "$2" "$3"
    else
        plain_timer $min "$2" "$3"
    fi
}

print_label () {
    bold=$(tput bold)
    normal=$(tput sgr0)
    printf " ${bold}$1${normal}"
    [ ! -z $2 ] && printf " $2"
}



#===[ OPTIONS ]==============================================================#

# defaults to be overwritten by command-line options
COUNTDOWN_STDOUT=false
COUNTDOWN_FILE=false
LABELS=false
NOTIFY=false
PLAY_SOUND=true
POMODORO=false
REPEAT=false
PREDEF_SEQ=false

# PARSE OPTIONS
while getopts "b:hcClnpqrs" OPT; do
    case $OPT in
        h) ## help
            show_help              ;;
        b) ## "/path/to/bell-sound.mp3"
            SOUND="$OPTARG"        ;;
        c) ## countdown timer mode
            COUNTDOWN_STDOUT=true  ;;
        C) ## write countdown state to file (-c is implied)
            COUNTDOWN_STDOUT=true
            COUNTDOWN_FILE=true    ;;
        l) ## show interval labels
            LABELS=true            ;;
        n) ## send notification on interval changes
            NOTIFY=true            ;;
        p) ## pomodoro technique
            POMODORO=true          ;;
        q) ## quiet, no bell sound on interval changes
            PLAY_SOUND=false       ;;
        r) ## repeat forever (same as 'X/Y')
            REPEAT=true            ;;
        s) ## use a predefined interval sequence
            PREDEF_SEQ=true        ;;
    esac
done

# PARSE REMAINING ARGS
shift $(expr $OPTIND - 1)

if $POMODORO ; then
    TIMER=$DEFAULT_TIMER
    BREAK=$DEFAULT_BREAK
    LONGBREAK=$DEFAULT_LONGBREAK
    REPEAT=false

elif $PREDEF_SEQ ; then
    echo -e "\nPredefined time sequence: $DEFAULT_SEQUENCE\n"
    TIMER=$DEFAULT_SEQUENCE
    REPEAT=false

elif [ -z $1 ] ; then
    TIMER=$DEFAULT_TIMER

elif [[ $1 == *"/"* ]]; then
    # an argument formatted as 'X/Y' means repetition
    REPEAT=true  # the session will loop until user break
    TIMER=$(check_num $(echo $1 | cut -d"/" -f1) $DEFAULT_TIMER)
    BREAK=$(check_num $(echo $1 | cut -d"/" -f2) $DEFAULT_BREAK)

else
    if $REPEAT ; then
        TIMER=$(check_num $1 $DEFAULT_TIMER)
        BREAK=$(check_num $2 $DEFAULT_BREAK)
    else
        TIMER=$(for t in $@ ; do
                    check_num $t $DEFAULT_TIMER
                    printf " "
                done)
    fi
fi



#===[ MAIN: TIMER ]==========================================================#

if $POMODORO ; then
    LABEL_TMP=$LABEL_BREAK
    for p in $(eval echo {1..$POMODOROS}) ; do

        PNUMBER="$p/$POMODOROS"

        run_timer $TIMER "$LABEL_WORKING" "$PNUMBER"

        # make a long break if needed
        if [[ $p -eq $(( LONGBREAK_AFTER + 1 )) ]] ; then
            BREAK=$DEFAULT_LONGBREAK
            LABEL_BREAK=$LABEL_LONGBREAK
        else
            BREAK=$DEFAULT_BREAK
            LABEL_BREAK=$LABEL_TMP
        fi

        # skip last break
        if [[ $p -ne $POMODOROS ]] ; then
            run_timer $BREAK "$LABEL_BREAK" "$PNUMBER"
        fi
    done
    echo -e "\nDONE!\n"


elif $REPEAT ; then
    echo -e "\nSET: ${TIMER}m/${BREAK}m [oo] (^C to quit)\n"
    while :; do
        run_timer $TIMER "$LABEL_WORKING"
        run_timer $BREAK "$LABEL_BREAK"
    done

else
    echo
    for minutes in $TIMER ; do
        run_timer $minutes "\b"
    done
    echo
fi
