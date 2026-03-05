#!/bin/bash
PID="$1"

if [[ -z "$PID" ]] || ! [[ "$PID" =~ ^[0-9]+$ ]]; then
    echo "Error: Invalid or missing PID ($PID)"
    exit 1
fi

while kill -0 "$PID" 2>/dev/null; do
    sleep 5
done

echo "Tests finished"
