#!/usr/bin/env bash

# Constants
PKGMAN=pacman
PKGMAN_ARG=-Qi

# Colors Code
YELLOW="\e[33m"
RED="\e[31m"
RESET_COLOR="\e[0m"

# Variables
isFreeSystem=1
numbOfNonFreeSoftware=0

# Locales
WARNING_PART1_STR="${YELLOW}WARNING:${RESET_COLOR}Proprietary Package"
WARNING_PART2_STR="is INSTALLED"

function verify_arch_pkg() {
    while IFS= read -r package; do
        if $PKGMAN $PKGMAN_ARG "$package" &> /dev/null; then
            echo -e "${WARNING_PART1_STR} ${RED}$package${RESET_COLOR} ${WARNING_PART2_STR}"
            isFreeSystem=0
            numbOfNonFreeSoftware=$((${numbOfNonFreeSoftware} + 1))
        fi
    done < data/pkglist.txt
}

function check_software() {
    verify_arch_pkg
    if [[ "$isFreeSystem" == "1" ]]; then 
        echo "Congrats! Your system contain 100% percent of free software!"
    else
        echo "Yours system contains ${numbOfNonFreeSoftware} knowns non-free packages"
    fi
}

function main() {
    if [[ "$1" == "Arch" ]]; then 
        check_software 
    fi
    if [[ "$1" == "--help" ]]; then
        echo "Check well know proprietary packages on your system"
    fi
}

main