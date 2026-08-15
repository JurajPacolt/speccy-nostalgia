@echo off
setlocal
set "PROJECT_DIR=%~dp0"

pushd "%PROJECT_DIR%"
sjasmplus -Isrc src/main.asm
set "BUILD_EXIT_CODE=%ERRORLEVEL%"
if not "%BUILD_EXIT_CODE%"=="0" (
    popd
    exit /b %BUILD_EXIT_CODE%
)

start "" SpecEmu "%PROJECT_DIR%DarkIsland1.sna"
set "RUN_EXIT_CODE=%ERRORLEVEL%"
popd
exit /b %RUN_EXIT_CODE%
