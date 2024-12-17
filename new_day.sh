set -e
XX=$1

# if XX is not a number, exit
if ! [[ $XX =~ ^[0-9]+$ ]]; then
    echo "Usage: $0 <day>"
    exit 1
fi


[ ${#XX} -eq 1 ] && XX="0$XX"
[ $XX -gt 25 ] && echo "Day must be between 1 and 25" && exit 1
[ $XX -lt 1 ] && echo "Day must be between 1 and 25" && exit 1

DAYXX="day$XX"

[ -d $"day/{DAYXX}" ] && echo "Folder for day $XX already exists" && exit 1

mkdir src/$DAYXX
cp -r src/day00/* src/$DAYXX

# Make dummy data

touch data/full/$DAYXX.txt
touch data/test/$DAYXX.txt

echo "data for $DAYXX" > data/full/$DAYXX.txt
echo "data for $DAYXX" > data/test/$DAYXX.txt
