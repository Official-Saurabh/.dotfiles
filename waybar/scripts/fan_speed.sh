#!/bin/bash
SPEEDS=$(nbfc status | grep "Current Fan Speed" | awk '{print $5}' | sed 's/\..*//')

if [ -z "$SPEEDS" ]; then
    # Return percentage 0 so the config displays "Icon 0%" or similar
    # You can also change "text" to "Offline" if you prefer reading text over %
    echo "{\"text\": \"Offline\", \"percentage\": 0, \"class\": \"critical\"}"
else
    AVG_SPEED=$(echo "$SPEEDS" | awk '{sum+=$1; count++} END {if (count > 0) print int(sum/count); else print 0}')
    echo "{\"text\": \"$AVG_SPEED%\", \"percentage\": $AVG_SPEED}"
fi