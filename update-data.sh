#!/usr/bin/env bash

# CONSTANTS/SYNTHAX :
BLACKLISTS=( aur-blacklist.txt                 \
                      blacklist.txt                     \
                      your-gaming-freedom-blacklist.txt \
                      your-init-freedom-blacklist.txt   \
                      your-privacy-blacklist.txt        )
REF_REGEX='^[^:]*:[^:]*::[^:]*:.*$'
SYNTAX_REGEX='^[^:]*:[^:]*:(debian|fedora|fsf|parabola|savannah)?:[^:]*:.*$'
CSV_CHAR=':'
SEP_CHAR='!'   

if [[ "$1" == "--install" ]]; then
    sudo mkdir -p /usr/local/share/xgui4-scripts/
    cp data /usr/local/share/xgui4-scripts/data
fi

if [[ "$1" == "--update" ]]; then
    if [[ -f  /usr/local/share/xgui4-scripts/data ]];then

        echo "do not worry it wont be empty"
    else
        echo "The data files are not installed yet"; 
    fi 
fi