#!/bin/sh

wine /hdd01/progz/sjasmplus/sjasmplus.exe -Isrc main.asm
if [ $? -eq 0 ] 
  then
    myfuse $PWD/Dillen.sna
fi
