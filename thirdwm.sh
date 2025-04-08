#!/usr/bin/env bash
#constants
WIDTH=1920
MAIN_WIDTH=1220
HEIGHT=1080
HALF_H=$((HEIGHT/2))
#statically account (more or less) for decorators fucking everithing up
DEC_BORDER=0
# window manager metadata
WSPACE=$(wmctrl -d | grep '\*' | awk -F ' ' '{print $1}')
echo "$WSPACE" #get current workspace
echo ""
WINDOWS=$(wmctrl -l | grep " $WSPACE " | grep -o 'luca.*') #| awk -F ' ' '{print $2}' 
# rremove only first word from each line, keep all the rest
WINDOWS=$(echo "$WINDOWS" | awk '{for(i=2;i<=NF;++i)printf "%s%s", $i, (i==NF?ORS:OFS)}')
# WINDOWS=$(echo "$WINDOWS" | awk -F ' ' '{print $2}')
# remove Desktop from list
WINDOWS=$(echo "$WINDOWS" | grep -v "Desktop")
echo "$WINDOWS" #get all open windows by name
WIDS=$(wmctrl -l | grep " $WSPACE " | grep -o '0x.*' | awk -F ' ' '{print $1}')
echo "$WIDS" #get all open windows by id
echo ""

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
# if $WINDOWS is empty, dmenu list of common apps (from the dock)
# some parts are still broken
# TODO : fix the case when no windows are open
if [ -z "$WINDOWS" ]; then
    echo "No windows open"
    # select through dmenu the 3 windows to use out of all open windows
    SELECTED=$(echo "$common_apps" | dmenu -l 10 -p "Select main window" -i)
    #if no window selected, exit
    if [ -z "$SELECTED" ]; then
        exit 1
    fi
    #append an other window to the list
    SELECTED="$SELECTED
    $(echo "$common_apps" | grep -v "$SELECTED" | dmenu -l 10 -p "Select 2nd window" -i)"
    SELECTED="$SELECTED
    $(echo "$common_apps" | grep -v "$SELECTED" | dmenu -l 10 -p "Select 3rd window" -i)"
    echo "$SELECTED"

    # start the selected apps in the current workspace
    for app in $SELECTED; do
        $app &
        # wait for the app to start
        sleep 1
        # put the app in the current workspace
        WID=$(wmctrl -l | grep "$app" | grep -o '0x.*' | awk -F ' ' '{print $1}')
        wmctrl -i -r $WID -t $WSPACE
    done
    sleep 5
    # update the list of windows
    WINDOWS=$(wmctrl -l | grep " $WSPACE " | grep -o 'luca.*' | awk -F ' ' '{print $2}')
    echo "$WINDOWS"
    # update the list of window ids
    WIDS=$(wmctrl -l | grep " $WSPACE " | grep -o '0x.*' | awk -F ' ' '{print $1}')
    echo "$WIDS"

    WSPACE=$(wmctrl -d | grep '\*' | awk -F ' ' '{print $1}')
    WINDOWS=$(wmctrl -l | grep " $WSPACE " | grep -o 'luca.*') #| awk -F ' ' '{print $2}' 
    WINDOWS=$(echo "$WINDOWS" | awk '{for(i=2;i<=NF;++i)printf "%s%s", $i, (i==NF?ORS:OFS)}')
    WINDOWS=$(echo "$WINDOWS" | grep -v "Desktop")

    SELECTED="$WINDOWS"

# if exactly 3 windows are open, use them
elif [ $(echo "$WINDOWS" | wc -l) -eq 3 ]; then
    # TODO : add main selection
    declare -a SELECTED
    echo "3 windows open"
    echo "$WINDOWS"
    # choose manually first window
    SELECTED[0]=$(echo "$WINDOWS" | dmenu -l 10 -p "Select main window" -i)
    #append the remaining two windows to the list without manual selection
    SELECTED[1]="$(echo "$WINDOWS" | grep -v "$SELECTED" | head -n 1)"
    SELECTED[2]="$(echo "$WINDOWS" | grep -v "$SELECTED" | tail -n 1)"

    if [ -z "$SELECTED" ]; then
        exit 1
    fi
    echo "$SELECTED"

else # manual selection
    declare -a SELECTED
    # select through dmenu the 3 windows to use out of all open windows
    SELECTED[0]=$(echo "$WINDOWS" | dmenu -l 10 -p "Select main window" -i)
    if [ -z "$SELECTED" ]; then
        exit 1
    fi
    #append an other window to the list
    SELECTED[1]=$(echo "$WINDOWS" | grep -v "$SELECTED" | dmenu -l 10 -p "Select 2nd window" -i)
    SELECTED[2]=$(echo "$WINDOWS" | grep -v "$SELECTED" | dmenu -l 10 -p "Select 3rd window" -i)
    # TODO : if same window selected twice then open new instance
    echo "$SELECTED"
fi


#select big on right or left
BIG=$(echo "left
right" | dmenu -l 2 -p "Big window on left or right?" -i)
echo "$BIG"
if [ -z "$BIG" ]; then
    exit 1
fi

# generate workspace layout
# SIZES_RIGHT=("0,$((WIDTH-MAIN_WIDTH)),0,$MAIN_WIDTH,$HEIGHT" # main window
#             "0,0,0,$((WIDTH-MAIN_WIDTH)),$HALF_H" # top
#             "0,0,$HALF_H,$((WIDTH-MAIN_WIDTH)),$HALF_H" # bottom
#             )
# SIZES_LEFT=("0,0,0,$MAIN_WIDTH,$HEIGHT" # main window
#             "0,$((MAIN_WIDTH)),0,$((WIDTH-MAIN_WIDTH)),$HALF_H" # top
#             "0,$((MAIN_WIDTH)),$HALF_H,$((WIDTH-MAIN_WIDTH)),$HALF_H" # bottom
#             )
# echo "${SIZES_RIGHT[*]}"
# echo "${SIZES_LEFT[*]}"

if [ "$BIG" = "right" ]; then
    echo "right"
    LAYOUT=("0,$((WIDTH-MAIN_WIDTH)),0,$((MAIN_WIDTH+DEC_BORDER)),$((HEIGHT+DEC_BORDER))" # main window
            "0,$((-DEC_BORDER)),$((-DEC_BORDER)),$((WIDTH-MAIN_WIDTH+DEC_BORDER)),$((HALF_H+DEC_BORDER))" # top
            "0,$((-DEC_BORDER)),$((HALF_H-DEC_BORDER)),$((WIDTH-MAIN_WIDTH+DEC_BORDER)),$((HALF_H+DEC_BORDER))" # bottom
            )
else 
    echo "left"
    LAYOUT=("0,0,0,$MAIN_WIDTH,$HEIGHT" # main window
            "0,$((MAIN_WIDTH)),0,$((WIDTH-MAIN_WIDTH)),$HALF_H" # top
            "0,$((MAIN_WIDTH)),$HALF_H,$((WIDTH-MAIN_WIDTH)),$HALF_H" # bottom
            )
fi
echo layouts:
echo "${LAYOUT[0]}"
echo "${LAYOUT[1]}"
echo "${LAYOUT[2]}"
# # get the id of the selected windows
# WID1=$(echo "$WIDS" | grep -n "$SELECTED" | grep -o '^[^:]*')
# WID2=$(echo "$WIDS" | grep -n "$SELECTED" | grep -o ':[^:]*' | grep -o '[^:]*' | grep -o '^[^ ]*')
# WID3=$(echo "$WIDS" | grep -n "$SELECTED" | grep -o ':[^:]*' | grep -o '[^:]*' | grep -o '[^ ]*')
# echo "$WID1 $WID2 $WID3"
i=0
echo "selected: "
echo "${SELECTED[0]}"
echo "${SELECTED[1]}"
echo "${SELECTED[2]}"
echo " "
# cycle through selected windows by line

# while WIN_NAME= read -r $SELECTED; do
#     echo "$WIN_NAME ${LAYOUT[$i]} $i"
#     # wmctrl -r $WIN_NAME -b remove,fullscreen
#     # wmctrl -r $WIN_NAME -b remove,maximized_vert,maximized_horz
#     # wmctrl -r $WIN_NAME -e ${LAYOUT[$i]}; wmctrl -R $WIN_NAME
#     i=$((i+1))
# done <<< "$SELECTED"

# wmctrl -R $WIN_NAME ${SIZES[$i]}
# wmctrl -r <WID> -i -b remove,fullscreen
# wmctrl -r <WID> -i -b remove,maximized_vert,maximized_horz
# wmctrl -i -r <WID> -e <MVARG>; wmctrl -i -R <WID>

echo "----------"
echo "${SELECTED[0]} ${LAYOUT[0]} 0"
echo " "
wmctrl -r ${SELECTED[0]} -b remove,fullscreen
wmctrl -r ${SELECTED[0]} -b remove,maximized_vert,maximized_horz
wmctrl -r ${SELECTED[0]} -e ${LAYOUT[0]}
wmctrl -R ${SELECTED[0]}
# wmctrl -r ${SELECTED[0]} -b add,sticky
echo "${SELECTED[1]} ${LAYOUT[1]} 1"
echo " "
wmctrl -r ${SELECTED[1]} -b remove,fullscreen
wmctrl -r ${SELECTED[1]} -b remove,maximized_vert,maximized_horz
wmctrl -r ${SELECTED[1]} -e ${LAYOUT[1]}
wmctrl -R ${SELECTED[1]}
# wmctrl -r ${SELECTED[1]} -b add,sticky
echo "${SELECTED[2]} ${LAYOUT[2]} 2"
echo " "
wmctrl -r ${SELECTED[2]} -b remove,fullscreen
wmctrl -r ${SELECTED[2]} -b remove,maximized_vert,maximized_horz
wmctrl -r ${SELECTED[2]} -e ${LAYOUT[2]}
wmctrl -R ${SELECTED[2]}
# wmctrl -r ${SELECTED[1]} -b add,sticky
echo "----------"
wmctrl -R ${SELECTED[0]}