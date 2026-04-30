#!/bin/bash
count=$(checkupdates 2>/dev/null | wc -l)
if [ "$count" -gt 0 ]; then
    echo "{\"text\": \"󰚰 $count\", \"tooltip\": \"$count update(s) — click to open cachy-update\", \"class\": \"has-updates\"}"
else
    echo "{\"text\": \"\", \"tooltip\": \"Up to date\", \"class\": \"up-to-date\"}"
fi
