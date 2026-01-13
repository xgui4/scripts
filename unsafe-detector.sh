#!/usr/bin/env bash

if [ $1 = "--help" ]; then 
    echo "unsafe-detector.sh [directory to scan]"

sudo find "$1" -type f -name '*.rs' -exec grep -H 'unsafe' {} + | wc -l