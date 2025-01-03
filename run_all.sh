set -e

zig build

BIN_FOLDER=./zig-out/bin

DAYS=()
PARTS=()
RESULTS=()
N=0
for file in $(find ./zig-out/bin -name 'day*' -type f | sort); do
    BASENAME=$(basename $file)
    DAY=${BASENAME:3:2}
    PART=${BASENAME:6:1}

    FULL_FILE_PATH="./data/full/day${DAY}.txt"

    RESULT=$(cat $FULL_FILE_PATH | $file 2> /dev/null)
    echo "Result for $BASENAME is $RESULT"

    DAYS[$N]=$DAY
    PARTS[$N]=$PART
    RESULTS[$N]=$RESULT
    N=$((N + 1))
done

(
    echo "Day Part Result"
    for ((i = 0; i < ${#DAYS[@]}; i++)); do
        echo "${DAYS[$i]} ${PARTS[$i]} ${RESULTS[$i]}"
    done
) | column -t | tee results.txt

# Find the last non-zero result, print it and send it to pbcopy
for ((i = ${#RESULTS[@]} - 1; i >= 0; i--)); do
    if [ ${RESULTS[$i]} -ne 0 ]; then
        echo "Last non-zero result is ${DAYS[$i]} ${PARTS[$i]} ${RESULTS[$i]}"
        printf "${RESULTS[$i]}" | pbcopy
        break
    fi
done