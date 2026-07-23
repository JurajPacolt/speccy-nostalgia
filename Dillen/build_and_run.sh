#!/bin/sh

wine /hdd01/progz/sjasmplus/sjasmplus.exe -Isrc src/main.asm
if [ $? -eq 0 ] 
  then
    fbzx $PWD/Dillen.sna
fi
