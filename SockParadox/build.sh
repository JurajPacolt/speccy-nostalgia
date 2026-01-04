#!/bin/bash
HOME=$(dirname "$0")
SRC_DIR="$HOME/src"

echo "Generating game data..."
python generate_game_data.py

echo "Building game..."
sjasmplus -I$SRC_DIR main.asm
cd ..

echo "Done!"
