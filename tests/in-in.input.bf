#!/usr/bin/env bash

RESULT=$(cat $1)
# Brainfuck jumps should be safe here
if [[ $RESULT == "A" ]]; then
    exit 0
else
    exit 1
fi

# BrainFuck code: ,.
