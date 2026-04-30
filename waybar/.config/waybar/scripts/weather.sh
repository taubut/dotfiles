#!/bin/bash
# Weather for Boston, MA using Open-Meteo API (Fahrenheit)

data=$(curl -s 'https://api.open-meteo.com/v1/forecast?latitude=42.36&longitude=-71.06&current_weather=true&temperature_unit=fahrenheit' 2>/dev/null)

temp=$(echo "$data" | grep -oP '"temperature":\K[0-9.]+')
code=$(echo "$data" | grep -oP '"weathercode":\K[0-9]+')
is_day=$(echo "$data" | grep -oP '"is_day":\K[0-9]+')

# Map weather codes to icons
case $code in
    0) icon="☀️";;
    1|2|3) icon="⛅";;
    45|48) icon="🌫️";;
    51|53|55|56|57) icon="🌧️";;
    61|63|65|66|67) icon="🌧️";;
    71|73|75|77) icon="❄️";;
    80|81|82) icon="🌧️";;
    85|86) icon="❄️";;
    95|96|99) icon="⛈️";;
    *) icon="🌡️";;
esac

[ "$is_day" = "0" ] && [ "$code" = "0" ] && icon="🌙"

printf "%.0f°F" "$temp"
