#!/bin/bash
# wu-temps.sh — pulls current PWS observations + NOAA severe alerts
# Rewritten to use jq for all JSON parsing — no more positional awk hacks

DTE=$(date +%Y-%m-%d)
WORKDIR="/home/riley"
APIURL='https://api.weather.com/v2/pws/observations/current?stationId=KVAWAYNE72&format=json&units=e&apiKey=YOUR_API_KEY_HERE'
NOAA_ALERTS_URL="https://api.weather.gov/alerts/active?point=38.06,-78.88&severity=Severe,Extreme"
APITEMPFL="/tmp/localinfo"
LOGFILE="$WORKDIR/api-lookups/localdata/temps.log"
LCURTEMP="$WORKDIR/api-lookups/localdata/lcurtemp"
CURTEMP="$WORKDIR/api-lookups/localdata/curtemp"
LCURHUM="$WORKDIR/api-lookups/localdata/lrhum"
CURHUM="$WORKDIR/api-lookups/localdata/rhum"
LCURDP="$WORKDIR/api-lookups/localdata/lcurdp"
CURDP="$WORKDIR/api-lookups/localdata/curdp"
ALERT_FILE="$WORKDIR/api-lookups/localdata/ALERT"
CONDITIONS_FILE="$WORKDIR/api-lookups/localdata/conditions"
CONDITIONS_FILE_OLD="$WORKDIR/api-lookups/localdata/conditions_old"
ALERT_JSON="$WORKDIR/api-lookups/localdata/alert-$DTE.txt"
MQTTENA="True"
MQTTBROKER="192.168.1.202"
MQTTTOPIC="weather/temp/"
MQTTTOPIC2="weather/observed/"
MQTTTOPIC3="weather/forecast/"
MQTTTOPIC4="weather/"

# ── Fetch PWS observations ─────────────────────────────────────
curl -s "$APIURL" > "$APITEMPFL"

# Sanity check
if ! jq -e '.observations[0]' "$APITEMPFL" > /dev/null 2>&1; then
    echo "$(date '+%m%d%y_%H:%M')|ERROR: bad PWS API response" >> "$LOGFILE"
    cat "$APITEMPFL"
    exit 1
fi

# Parse with jq — field names, not positions
# imperial sub-object holds temp, dewpt, heatIndex etc when units=e
temp_f=$(jq -r '.observations[0].imperial.temp  // empty' "$APITEMPFL")
humi=$(jq   -r '.observations[0].humidity       // empty' "$APITEMPFL")
dewpnt=$(jq -r '.observations[0].imperial.dewpt // empty' "$APITEMPFL")

# ── Update files ───────────────────────────────────────────────
if [ -n "$temp_f" ]; then
    echo "$temp_f" > "$CURTEMP"
    echo "$temp_f" > "$LCURTEMP"
else
    cp "$LCURTEMP" "$CURTEMP"
fi

if [ -n "$humi" ]; then
    echo "$humi" > "$CURHUM"
    echo "$humi" > "$LCURHUM"
else
    cp "$LCURHUM" "$CURHUM"
fi

if [ -n "$dewpnt" ]; then
    echo "$dewpnt" > "$CURDP"
    echo "$dewpnt" > "$LCURDP"
else
    cp "$LCURDP" "$CURDP"
fi

# ── Log ───────────────────────────────────────────────────────
echo "$(date '+%m%d%y_%H:%M')|CUR:$(cat $CURTEMP)|HUM:$(cat $CURHUM)|DEWPNT:$(cat $CURDP)" >> "$LOGFILE"

# ── MQTT current observations ─────────────────────────────────
if [[ "$MQTTENA" == "True" ]]; then
    mosquitto_pub -h "$MQTTBROKER" -r -t "${MQTTTOPIC}CURRENT"  -m "$(cat $CURTEMP)"
    mosquitto_pub -h "$MQTTBROKER" -r -t "${MQTTTOPIC2}HUMIDITY" -m "$(cat $CURHUM)"
    mosquitto_pub -h "$MQTTBROKER" -r -t "${MQTTTOPIC2}DEWPNT"  -m "$(cat $CURDP)"
else
    echo "MQTT disabled"
fi

# ── NOAA severe weather alerts ────────────────────────────────
NOAA_RESPONSE=$(curl -s -H "User-Agent: weather-script/1.0 (riley@example.com)" "$NOAA_ALERTS_URL")

if echo "$NOAA_RESPONSE" | jq -e '.features | length > 0' > /dev/null 2>&1; then
    # Alert exists
    echo "$NOAA_RESPONSE" > "$ALERT_JSON"
    echo "ALERT" > "$ALERT_FILE"
    cp "$CONDITIONS_FILE" "$CONDITIONS_FILE_OLD"

    HEADLINE=$(echo "$NOAA_RESPONSE" | jq -r '.features[0].properties.headline' | awk '{print $1 " " $2}')
    echo "$HEADLINE" > "$CONDITIONS_FILE"

    if [[ "$MQTTENA" == "True" ]]; then
        mosquitto_pub -h "$MQTTBROKER" -r -t "${MQTTTOPIC3}COND_OLD" -m "$(cat $CONDITIONS_FILE_OLD)"
        mosquitto_pub -h "$MQTTBROKER" -r -t "${MQTTTOPIC3}COND"     -m "$HEADLINE"
        mosquitto_pub -h "$MQTTBROKER" -r -t "${MQTTTOPIC4}ALERT"    -m "ALERT"
    fi
else
    # No alerts
    echo "" > "$ALERT_FILE"
    cp "$CONDITIONS_FILE_OLD" "$CONDITIONS_FILE"

    if [[ "$MQTTENA" == "True" ]]; then
        mosquitto_pub -h "$MQTTBROKER" -r -t "${MQTTTOPIC4}ALERT" -m "Clear"
    fi
fi
