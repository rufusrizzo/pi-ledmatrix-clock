#!/bin/bash
# wu-forecast.sh — pulls 5-day forecast from Weather.com API
# Rewritten to use jq for all JSON parsing — no more positional awk hacks
# Suggest running around 23:00 for tomorrow's temps

DTE=$(date +%Y-%m-%d)
WORKDIR="/home/riley"
APIURL='https://api.weather.com/v3/wx/forecast/daily/5day?geocode=38.06,-78.88&format=json&units=e&language=en-US&apiKey=YOUR_API_KEY_HERE'
LOGFILE="$WORKDIR/api-lookups/localdata/temps.log"
MAXFORE="$WORKDIR/api-lookups/localdata/max"
MINFORE="$WORKDIR/api-lookups/localdata/min"
MAXFORE2="$WORKDIR/api-lookups/localdata/max2"
MINFORE2="$WORKDIR/api-lookups/localdata/min2"
LMAXFORE="$WORKDIR/api-lookups/localdata/lastmax"
LMINFORE="$WORKDIR/api-lookups/localdata/lastmin"
THUNDERCAST="$WORKDIR/api-lookups/localdata/thunder"
CONDFORE="$WORKDIR/api-lookups/localdata/conditions"
ADVFORE="$WORKDIR/api-lookups/localdata/advforecast"
APIFILE="/tmp/wu-forecast-out"
MQTTENA="True"
MQTTBROKER="192.168.1.202"
MQTTTOPIC="weather/temp/"
MQTTTOPIC3="weather/forecast/"

# ── Fetch ─────────────────────────────────────────────────────
curl -s "$APIURL" > "$APIFILE"

# Sanity check — if the API returned an error or empty, bail out
if ! jq -e '.temperatureMax' "$APIFILE" > /dev/null 2>&1; then
    echo "$(date '+%m%d%y_%H:%M')|ERROR: bad API response" >> "$LOGFILE"
    cat "$APIFILE"   # print whatever we got for debugging
    exit 1
fi

# ── Temperatures ──────────────────────────────────────────────
# Index 0 = today, index 1 = tomorrow
HItempT=$(jq -r '.temperatureMax[1]' "$APIFILE")
LOWtempT=$(jq -r '.temperatureMin[1]' "$APIFILE")

# Overall max/min across the whole 5-day window
HItempT2=$(jq '[.temperatureMax[]] | max' "$APIFILE")
LOWtempT2=$(jq '[.temperatureMin[]] | min' "$APIFILE")

# ── Thunder index ─────────────────────────────────────────────
# daypart[] is interleaved D/N: 0=Today, 1=Tonight, 2=Tomorrow, 3=TomorrowNight...
# Index 2 = Tomorrow daytime thunder index
THUNDER=$(jq -r '.daypart[0].thunderIndex[2] // 0' "$APIFILE")

# ── Conditions (tomorrow daytime phrase) ─────────────────────
CONDITIONS=$(jq -r '.daypart[0].wxPhraseLong[2] // "Unknown"' "$APIFILE")

# ── Advanced forecast: which day indices have bad weather ─────
# Checks narrative for each day (0-5) for rain/snow/storm/ice/thunder
ADVWEATHER=$(jq -r '
  .narrative | to_entries[] |
  select(.value | test("rain|snow|storm|ice|tornado|thunder"; "i")) |
  .key
' "$APIFILE" | tr '\n' ' ' | sed 's/ *$//')

# ── Write temp files ──────────────────────────────────────────
if [ -n "$HItempT" ] && [ "$HItempT" != "null" ]; then
    echo "$HItempT"  > "$MAXFORE"
    echo "$HItempT2" > "$MAXFORE2"
    echo "$HItempT"  > "$LMAXFORE"
else
    cat "$LMAXFORE"  > "$MAXFORE"
fi

if [ -n "$LOWtempT" ] && [ "$LOWtempT" != "null" ]; then
    echo "$LOWtempT"  > "$MINFORE"
    echo "$LOWtempT2" > "$MINFORE2"
    echo "$LOWtempT"  > "$LMINFORE"
else
    cat "$LMINFORE" > "$MINFORE"
fi

# ── Thunder display ───────────────────────────────────────────
case $THUNDER in
    0) echo '_'     > "$THUNDERCAST" ;;
    1) echo '|'     > "$THUNDERCAST" ;;
    2) echo '||'    > "$THUNDERCAST" ;;
    3) echo '|||'   > "$THUNDERCAST" ;;
    4) echo '||||'  > "$THUNDERCAST" ;;
    5) echo '|||||' > "$THUNDERCAST" ;;
    *) echo '???'   > "$THUNDERCAST" ;;
esac

# ── Conditions / advanced forecast ───────────────────────────
if [ -n "$CONDITIONS" ]; then
    echo "$CONDITIONS" > "$CONDFORE"
fi

if [ -n "$ADVWEATHER" ]; then
    echo "$ADVWEATHER" > "$ADVFORE"
else
    echo "Clear" > "$ADVFORE"
fi

# ── Log ───────────────────────────────────────────────────────
echo "$(date '+%m%d%y_%H:%M')|THUNDER:$(cat $THUNDERCAST),$THUNDER|MAX:$(cat $MAXFORE)|MIN:$(cat $MINFORE)|MAX2:$(cat $MAXFORE2)|MIN2:$(cat $MINFORE2)|COND:$(cat $CONDFORE)|ADVFORE:$(cat $ADVFORE)" >> "$LOGFILE"

# ── MQTT ──────────────────────────────────────────────────────
if [[ "$MQTTENA" == "True" ]]; then
    mosquitto_pub -h "$MQTTBROKER" -r -t "${MQTTTOPIC}HIGH"      -m "$(cat $MAXFORE)"
    mosquitto_pub -h "$MQTTBROKER" -r -t "${MQTTTOPIC}LOW"       -m "$(cat $MINFORE)"
    mosquitto_pub -h "$MQTTBROKER" -r -t "${MQTTTOPIC}HIGH2"     -m "$(cat $MAXFORE2)"
    mosquitto_pub -h "$MQTTBROKER" -r -t "${MQTTTOPIC}LOW2"      -m "$(cat $MINFORE2)"
    mosquitto_pub -h "$MQTTBROKER" -r -t "${MQTTTOPIC3}THUNDER"  -m "$(cat $THUNDERCAST)"
    mosquitto_pub -h "$MQTTBROKER" -r -t "${MQTTTOPIC3}COND"     -m "$(cat $CONDFORE)"
    mosquitto_pub -h "$MQTTBROKER" -r -t "${MQTTTOPIC3}ADVFORE"  -m "$(cat $ADVFORE)"
else
    echo "MQTT disabled"
fi
