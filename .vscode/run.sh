#!/usr/bin/env bash
# https://github.com/MarcinKonowalczyk/run_sh
# Bash script run by a keyboard shortcut, called with the current file path $1
# This is intended as an example, but also contains a bunch of useful path partitions
# Feel free to delete everything in here and make it do whatever you want.

printf "Hello from run script! ^_^\n"

_VERSION="0.2.3" # Version of this script

# The directory of the main project from which this script is running
# https://stackoverflow.com/a/246128/2531987
ROOT_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_FOLDER="${ROOT_FOLDER%/*}"   # Strip .vscode folder
PROJECT_NAME="${ROOT_FOLDER##*/}" # Project name

FULL_FILE_PATH="$1"
_RELATIVE_FILE_PATH="${FULL_FILE_PATH##*$ROOT_FOLDER/}" # Relative path of the current file

# Split the relative file path into an array
RELATIVE_PATH_PARTS=(${_RELATIVE_FILE_PATH//\// })
DEPTH=${#RELATIVE_PATH_PARTS[@]}
DEPTH=$((DEPTH - 1))

# Couple of useful variables
FILENAME="${RELATIVE_PATH_PARTS[$DEPTH]}"

# If the file has an extension, get it otherwise set it to empty string
EXTENSION="" && [[ "$FILENAME" == *.* ]] && EXTENSION="${FILENAME##*.}"

########################################

GREEN='\033[0;32m';YELLOW='\033[0;33m';RED='\033[0;31m';PURPLE='\033[0;34m';DARK_GRAY='\033[1;30m';NC='\033[0m';

function logo() {
    TEXT=(
        " ______   __  __   __   __ " "    " "    ______   __  __   "
        "/\\  == \\ /\\ \\/\\ \\ /\\ \"-.\\ \\ " "    " "  /\\  ___\\ /\\ \\_\\ \\  "
        "\\ \\  __< \\ \\ \\_\\ \\\\\\ \\ \\-.  \\ " "  __" " \\ \\___  \\\\\\ \\  __ \\ "
        " \\ \\_\\ \\_\\\\\\ \\_____\\\\\\ \\_\\\\ \\\"\\_\\ " "/\\_\\\\" " \\/\\_____\\\\\\ \\_\\ \\_\\\\"
        "  \\/_/ /_/ \\/_____/ \\/_/ \\/_/ " "\\/_/" "  \\/_____/ \\/_/\\/_/"
    )
    printf "$PURPLE${TEXT[0]}$DARK_GRAY${TEXT[1]}$PURPLE${TEXT[2]}$NC\n"
    printf "$PURPLE${TEXT[3]}$DARK_GRAY${TEXT[4]}$PURPLE${TEXT[5]}$NC\n"
    printf "$PURPLE${TEXT[6]}$DARK_GRAY${TEXT[7]}$PURPLE${TEXT[8]}$NC\n"
    printf "$PURPLE${TEXT[9]}$DARK_GRAY${TEXT[10]}$PURPLE${TEXT[11]}$NC\n"
    printf "$PURPLE${TEXT[12]}$DARK_GRAY${TEXT[13]}$PURPLE${TEXT[14]} ${DARK_GRAY}v${_VERSION}$NC\n"
    printf "\n"
}

function info() {
    printf "PROJECT_NAME        : $GREEN${PROJECT_NAME}$NC  # project name (name of the project folder)\n"
    printf "RELATIVE_PATH_PARTS : $GREEN${RELATIVE_PATH_PARTS[@]}$NC  # relative path of the current file split into an array\n"
    printf "DEPTH               : $GREEN${DEPTH}$NC  # depth of the current file (number of folders deep)\n"
    printf "FILENAME            : $GREEN${FILENAME}$NC  # just the filename (equivalent to RELATIVE_PATH_PARTS[DEPTH])\n"
    printf "EXTENSION           : $GREEN${EXTENSION}$NC  # just the extension of the current file\n"
    printf "ROOT_FOLDER         : $GREEN${ROOT_FOLDER}$NC  # full path to the root folder of the project\n"
    printf "FULL_FILE_PATH      : $GREEN${FULL_FILE_PATH}$NC  # full path of the current file\n"
}

# VERBOSE=true
VERBOSE=false
[ "${RELATIVE_PATH_PARTS[0]}" = ".vscode" ] && [ ${RELATIVE_PATH_PARTS[$DEPTH]} = "run.sh" ] && [ $DEPTH -eq 1 ] && VERBOSE=true
if $VERBOSE; then
    logo
    info
    exit 0
fi

################################################################################


if [ $EXTENSION = "zig" ]; then
    if [[ $FILENAME == part* ]]; then
        DAY=${RELATIVE_PATH_PARTS[$((DEPTH - 1))]}
        DAY=${DAY:3}
        PART=${FILENAME:4:1}

        # echo "Day: $DAY"
        # echo "Part: $PART"
        echo "Running day $DAY part $PART"
        TEST_FILE_PATH="$ROOT_FOLDER/data/test/day$DAY.txt"
        FULL_FILE_PATH="$ROOT_FOLDER/data/full/day$DAY.txt"

        # if test file doesn't exist try to fallback to a test file with an underscore
        if [ ! -f $TEST_FILE_PATH ]; then
            TEST_FILE_PATH="$ROOT_FOLDER/data/test/day${DAY}_1.txt"
        fi

        (
            cd $ROOT_FOLDER
            # zig build --summary all
            zig build
            [ $? -ne 0 ] && exit 1
            # zig build test --summary all
            zig build test --summary all
            [ $? -ne 0 ] && exit 1
            cat $TEST_FILE_PATH | ./zig-out/bin/day${DAY}_${PART} | tee >(pbcopy)
            # cat $FULL_FILE_PATH | ./zig-out/bin/day${DAY}_${PART} | tee >(pbcopy)
            # ./zig-out/bin/day${DAY}_${PART}
        )
        # echo $TEST_FILE_PATH
        # echo $FULL_FILE_PATH
    elif [[ $FILENAME == build.zig ]]; then
        (
            echo "Running build.zig"
            cd $ROOT_FOLDER
            zig build
        )
    elif [[ $FILENAME == utils.zig ]]; then
        DAY=${RELATIVE_PATH_PARTS[$((DEPTH - 1))]}
        DAY=${DAY:3}
        (
            echo "Testing src/day$DAY/utils.zig"
            cd $ROOT_FOLDER
            zig test src/day$DAY/utils.zig
            [ $? -ne 0 ] && exit 1
        )
    elif [ "${RELATIVE_PATH_PARTS[${#RELATIVE_PATH_PARTS[@]} - 2]}" = "src" ]; then
        (
            echo "Testing src/$FILENAME"
            cd $ROOT_FOLDER
            zig test src/$FILENAME
            [ $? -ne 0 ] && exit 1
        )
    else
        echo "Nothing to do for $FILENAME"
    fi
    exit 0
fi

if [[ $FILENAME == run_all.sh ]]; then
    (
        echo "Running run_all.sh"
        cd $ROOT_FOLDER
        source ./run_all.sh
    )
    exit 0
fi

################################################################################

# Got to the end of the script. I guess there's nothing to do.

printf "Nothing to do for $GREEN${FULL_FILE_PATH}$NC\n"