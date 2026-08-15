@echo off
setlocal
set "PROJECT_DIR=%~dp0"

pushd "%PROJECT_DIR%"
sjasmplus -Isrc src/main.asm
set "BUILD_EXIT_CODE=%ERRORLEVEL%"
popd
pause
exit /b %BUILD_EXIT_CODE%
