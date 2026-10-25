#!/usr/bin/env bash

RESULT=$(cat $1 | xxd | awk '{print $2}')
# Brainfuck jumps should be safe here
if [[ $RESULT == "09" ]]; then
    exit 0
else
    exit 1
fi

# BrainFuck code: +++[>+++<-]>.
