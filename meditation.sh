#!/bin/bash

# meditation.sh v0.8 ~ timer para meditação
# bcardoso @ 2010-2021

#===[ USER CONFIG ]==========================================================#

BASEDIR="${HOME}/bin/meditation"

# default times
DEFAULT_TIMER=5
DEFAULT_BREAK=2
DEFAULT_LONGBREAK=7

# pomodoro: number of breaks before a long break
POMODOROS=7
LONGBREAK_AFTER=3 

# custom time sequence
CUSTOM_SEQUENCE="23 5 23 5 23" # 79m focus work (~20% of an 8h work-day)

# time labels
LABEL_WORKING="WORKING"
LABEL_BREAK="BREAK"
LABEL_LONGBREAK="LONG BREAK"

# player
#PLAYER="cvlc --play-and-exit"
#PLAYER="mpv --really-quiet --volume=50"
PLAYER="mplayer -really-quiet -volume 50"

# sound bell
# bigbowl.mp3: http://www.freesound.org/samplesViewSingle.php?id=132
#SOUND="$BASEDIR/sound/bigbowl.mp3"
# singing-bell: https://www.freesound.org/people/ryancacophony/sounds/202017/
#SOUND="$BASEDIR/sound/singing-bell-hit2.mp3"
SOUND="$BASEDIR/sound/singing-bell-hit2-normalized.mp3"



#===[ FUNCTIONS ]============================================================#

#  TODO: write proper help
show_help () {
    grep ") \#" $0 | sed -e 's/\t/\ /g;s/)\ \#/\t/g'
    echo
    exit
}

check_num () {
    [ $1 -gt 0 2> /dev/null ] && printf $1 || printf $2
}

plain_timer () {
    $NOTIFY && notify-send "$2 for $1 minutes... $3"
    printf "[$(date +%H:%M)"
    $LABELS && print_label "$2 $3"
    printf "]\t$1 min...\n"
    sleep "$1" #m
    $PLAY_SOUND && ($PLAYER $SOUND & 2> /dev/null)
}

countdown () {
    $NOTIFY && notify-send "$2 for $1 minutes... $3"
    clear
    echo
    $LABELS && print_label "$2 $3"
    for j in $(eval echo {$1..00}) ; do
        for i in {59..00} ; do
            tput cup 3 4
            printf "$j:$i "
            if $COUNTDOWN_FILE ; then
                printf "$2\n\n    $j:$i" > "$BASEDIR/countdown.txt"
            fi
            sleep 1
        done
    done
    $PLAY_SOUND && ($PLAYER $SOUND & 2> /dev/null)
}

print_label () {
    bold=$(tput bold)
    normal=$(tput sgr0)
    printf " ${bold}$1${normal}"
}



#===[ OPTIONS ]==============================================================#

# defaults (to be overwritten by command-line options)
COUNTDOWN_STDOUT=false
COUNTDOWN_FILE=false
LABELS=false
NOTIFY=false
PLAY_SOUND=true
POMODORO=false
REPEAT=false
SEQ_CUSTOM=false

# PARSE OPTIONS
#  TODO: write the FILE options
while getopts "b:hcClnpqrs" OPT; do
    case $OPT in
        h) show_help              ;;
        b) SOUND="$OPTARG"        ;;
        c) COUNTDOWN_STDOUT=true  ;;
        C) COUNTDOWN_STDOUT=true
           COUNTDOWN_FILE=true    ;;
        l) LABELS=true            ;;
        n) NOTIFY=true            ;;
        p) POMODORO=true          ;;
        q) PLAY_SOUND=false       ;;
        r) REPEAT=true            ;;
        s) SEQ_CUSTOM=true        ;;
    esac
done

# PARSE REMAINING ARGS
shift $(expr $OPTIND - 1)

if $POMODORO ; then
    TIMER=$DEFAULT_TIMER
    BREAK=$DEFAULT_BREAK
    LONGBREAK=$DEFAULT_LONGBREAK
    REPEAT=false
    
elif $SEQ_CUSTOM ; then
    echo -e "\nCustom time sequence: $CUSTOM_SEQUENCE\n"
    TIMER=$CUSTOM_SEQUENCE
    REPEAT=false

elif [ -z $1 ] ; then
    TIMER=$DEFAULT_TIMER
    
elif [[ $1 == *"/"* ]]; then
    # an argument formated as 'X/Y' means repetition
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

# echo "> timer: $TIMER"
# echo "> break: $BREAK"

if $POMODORO ; then
    LABEL_TMP=$LABEL_BREAK
    for p in $(eval echo {1..$POMODOROS}) ; do

        PNUMBER="$p/$POMODOROS"
        
        if $COUNTDOWN_STDOUT ; then
            countdown $(( TIMER - 1 )) "$LABEL_WORKING" "$PNUMBER"
        else
            plain_timer $TIMER "$LABEL_WORKING" "$PNUMBER"
        fi
        
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
            if $COUNTDOWN_STDOUT ; then
                countdown $(( BREAK - 1 )) "$LABEL_BREAK" "$PNUMBER"
            else
                plain_timer $BREAK "$LABEL_BREAK" "$PNUMBER"
            fi
        fi
    done
    echo -e "\nDONE!\n"

elif $REPEAT ; then
    echo -e "\nSET: ${TIMER}m/${BREAK}m [oo] (^C to quit)\n"
    while :; do
        if $COUNTDOWN_STDOUT ; then
            countdown $(( TIMER - 1 )) "$LABEL_WORKING"
            countdown $(( BREAK - 1 )) "$LABEL_BREAK"
        else
            plain_timer $TIMER "$LABEL_WORKING"
            plain_timer $BREAK "$LABEL_BREAK"
        fi
    done
    
else
    echo
    for minutes in $TIMER ; do
        if $COUNTDOWN_STDOUT ; then
            countdown $(( minutes - 1 ))
        else
            plain_timer $minutes "\b"
        fi
    done
    echo
fi

