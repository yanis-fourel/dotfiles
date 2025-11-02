#!/bin/sh

echo "{\"text\": \"...\", \"alt\": \"...\", \"class\": [\"process-inactive\"], \"percentage\": 0}"

while true; do
    FILE_PATH="/home/yanis/Videos/x2r/_external"
    DIR_PATH="/home/yanis/Videos/x2r/"

    if [ -e "$FILE_PATH" ]; then
        type="ex"
    else
        type="in"
    fi

    n=$(find "$DIR_PATH" -maxdepth 1 -mindepth 1 ! -name '.*' -printf '.' 2>/dev/null | wc -c)

    if pgrep -x ffmpeg -a | grep x2r > /dev/null; then
        echo "{\"text\": \"$type $n\", \"alt\": \"active\", \"class\": [\"process-active\"], \"percentage\": 100}"
    else
        echo "{\"text\": \"$type $n\", \"alt\": \"inactive\", \"class\": [\"process-inactive\"], \"percentage\": 0}"
    fi

    sleep 5
done
