#!/bin/sh

wine sjasmplus.exe -Isrc src/main.asm
if [ $? -eq 0 ]
  then
    fbzx $PWD/DarkIsland1.sna
fi
