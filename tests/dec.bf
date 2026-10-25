#!/usr/bin/env bash

RESULT=$(cat $1 | xxd | awk '{print $2}')
# Brainfuck jumps should be safe here
if [[ $RESULT == "ff" ]]; then
    exit 0
else
    echo $RESULT
    exit 1
fi

# BrainFuck code: -.
