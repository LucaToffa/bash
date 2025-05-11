#!/usr/bin/env bash

# constants
MACHINE=$(uname -n)
WIDTH=1600
MAIN_WIDTH=1220
HEIGHT=900
HALF_H=$((HEIGHT/2))
DEC_BORDER=0 #statically account (more or less) for decorators fucking everithing up
common_apps="firefox
code 
gnome-terminal
chromium %U --enable-features=TouchpadOverscrollHistoryNavigation
gnome-system-monitor
nemo ~
gnome-calculator
xreader
xed
kikad
rhythmbox %U"

# sanity checks

# if wmctrl or dmenu is not installed, exit
if ! command -v wmctrl &> /dev/null; then
    echo "wmctrl could not be found. Please install it."
    exit 1
fi
if ! command -v dmenu &> /dev/null; then
    echo "dmenu could not be found. Please install it."
    exit 1
fi
# if wmctrl -lG | awk 'NR==1{print $5}' is not equal to $WIDTH
# or wmctrl -lG | awk 'NR==1{print $5}' is not equal to $HEIGHT, exit
if [ $(wmctrl -lG | awk 'NR==1{print $5}') -ne $WIDTH ]; then
    echo "Screen width is not equal to $WIDTH. Please adjust your constants."
    exit 1
fi
if [ $(wmctrl -lG | awk 'NR==1{print $6}') -ne $HEIGHT ]; then
    echo "Screen height is not equal to $HEIGHT. Please adjust your constants."
    exit 1
fi

# window manager metadata

WSPACE=$(wmctrl -d | grep '\*' | awk -F ' ' '{print $1}') # current workspace
WINDOWS=$(wmctrl -l | sed '1 d'| grep " $WSPACE " | grep -o "$MACHINE.*") # all open windows by name
WINDOWS=$(echo "$WINDOWS" | awk '{for(i=2;i<=NF;++i)printf "%s%s", $i, (i==NF?ORS:OFS)}')
# echo "$WINDOWS" # get all open windows by name
WIDS=$(wmctrl -l | sed '1 d'| grep " $WSPACE " | grep -o '0x.*' | awk -F ' ' '{print $1}')

# selection logic
declare -a SELECTED
declare -a SELECTED_INDEX
declare -a SELECTED_WID
# if $WINDOWS is empty, dmenu list of common apps
#some parts are still broken
#TODO : fix the case when no windows are open
if [ -z "$WINDOWS" ]; then
    echo "No windows open"
# if exactly 3 windows are open, use them
elif [ $(echo "$WINDOWS" | wc -l) -eq 3 ]; then
    echo "3 windows open"
else # manual selection
    
    # select through dmenu the 3 windows to use out of all open windows
    SELECTED[0]=$(echo "$WINDOWS" | dmenu -l 10 -p "Select main window" -i)
    # which index in $WINDOWS is the selected window
    SELECTED_INDEX[0]=$(echo "$WINDOWS" | grep -n "${SELECTED[0]}" | cut -d: -f1)
    SELECTED_WID[0]=$(echo $WIDS | awk '{print $'"${SELECTED_INDEX[0]}"'}')
    # remove fisrt occurence of the selected window from the list
    el1=${SELECTED_INDEX[0]}
    echo "el1: $el1"
    WINDOWS[$el1]="%"
    if [ -z "$SELECTED" ]; then
        exit 1
    fi
    #append an other window to the list
    # instead od grep -v "${SELECTED[0]}" remove only first instance od the selected window
    SELECTED[1]=$(echo "$WINDOWS" | dmenu -l 10 -p "Select 2nd window" -i)
    SELECTED_INDEX[1]=$(echo "$WINDOWS" | grep -n "${SELECTED[1]}" | cut -d: -f1)
    SELECTED_WID[1]=$(echo $WIDS | awk '{print $'"${SELECTED_INDEX[1]}"'}')
    el2=${SELECTED_INDEX[1]}
    echo "el2: $el2"
    WINDOWS[$el2]="%"
    SELECTED[2]=$(echo "$WINDOWS" | dmenu -l 10 -p "Select 3rd window" -i)
    SELECTED_INDEX[2]=$(echo "$WINDOWS" | grep -n "${SELECTED[2]}" | cut -d: -f1)
    SELECTED_WID[2]=$(echo $WIDS | awk '{print $'"${SELECTED_INDEX[2]}"'}')
    echo "${SELECTED[@]}"
    echo "${SELECTED_INDEX[@]}"
    echo "${SELECTED_WID[@]}"
    echo "${WINDOWS[@]}"
fi

# select major side

# define layout

# remove win states and move to new position
