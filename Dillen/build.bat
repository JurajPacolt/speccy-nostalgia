@echo off
set HOME=%~dp0
set SRC_DIR=%HOME%\src
sjasmplus -I%SRC_DIR% main.asm
pause
