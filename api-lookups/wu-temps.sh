#!/bin/bash
# This script pulls max/min temps for tomorrow and checks for severe weather alerts.
# NOAA temperature forecast for the current day is unreliable.
# Suggest running this around 23:00 for tomorrow's temps.
#
# Get NOAA data for Waynesboro, VA (38.06, -78.88 based on your earlier example).
# To find your NOAA grid: https://api.weather.gov/points/38.0684,-78.8899
# To find local weather station: https://api.weather.gov/gridpoints/LWX/35,25/stations

DTE=`date +%Y-%m-%d`
DTET=`date --date="tomorrow" +%Y-%m-%d`
WORKDIR="/home/riley"
APIURL='https://api.weather.com/v2/pws/observations/current?stationId=KVAWAYNE72&format=json&units=e&apiKey=45b89a6bf9eb411fb89a6bf9eb011fac'
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
ALERT_JSON="$WORKDIR/api-lookups/localdata/alert-$DTE.txt"
# Setting MQTT parameters
MQTTENA="True"
MQTTBROKER="192.168.1.202"
MQTTTOPIC="weather/temp/"
MQTTTOPIC2="weather/observed/"

# Fetch current observations from Weather Underground
curl -s "$APIURL" > "$APITEMPFL"
temp_f=`cat "$APITEMPFL" | awk -F":" '{print $23}' | awk -F"," '{print $1}'`
humi=`cat "$APITEMPFL" | awk -F":" '{print $20}' | awk -F"," '{print $1}'`
dewpnt=`cat "$APITEMPFL" | awk -F":" '{print $25}' | awk -F"," '{print $1}'`

# Update temperature files
if [ -n "$temp_f" ]; then
    echo "$temp_f" > "$CURTEMP"
    echo "$temp_f" > "$LCURTEMP"
else
    cat "$LCURTEMP" > "$CURTEMP"
fi

# Update humidity files
if [ -n "$humi" ]; then
    echo "$humi" > "$CURHUM"
    echo "$humi" > "$LCURHUM"
else
    cat "$LCURHUM" > "$CURHUM"
fi

# Update dew point files
if [ -n "$dewpnt" ]; then
    echo "$dewpnt" > "$CURDP"
    echo "$dewpnt" > "$LCURDP"
else
    cat "$LCURDP" > "$CURDP"
fi

# Log the data
echo "`date "+%m%d%y_%H:%M"`|CUR:`cat ${CURTEMP}`|HUM:`cat ${CURHUM}`|DEWPNT:`cat ${CURDP}`" >> "$LOGFILE"

# If MQTT is enabled, publish data
if [[ "$MQTTENA" == "True" ]]; then
    mosquitto_pub -h "$MQTTBROKER" -r -t "${MQTTTOPIC}CURRENT" -m "`cat ${CURTEMP}`"
    mosquitto_pub -h "$MQTTBROKER" -r -t "${MQTTTOPIC2}HUMIDITY" -m "`cat ${CURHUM}`"
    mosquitto_pub -h "$MQTTBROKER" -r -t "${MQTTTOPIC2}DEWPNT" -m "`cat ${CURDP}`"
else
    echo "MQTT Is disabled"
fi

# Fetch NOAA severe weather alerts
NOAA_RESPONSE=$(curl -s -H "User-Agent: weather-script/1.0 (your.email@example.com)" "$NOAA_ALERTS_URL")

# Check if there are any severe or extreme alerts
if echo "$NOAA_RESPONSE" | jq -e '.features | length > 0' > /dev/null 2>&1; then
    #Severe or Extreme alert exists
    echo "$NOAA_RESPONSE" > "$ALERT_JSON"  # Write JSON to file
    echo "True" > "$ALERT_FILE"            # Write "True" to ALERT file
    
    #Extract the first two words of the first alert's headline
    HEADLINE=$(echo "$NOAA_RESPONSE" | jq -r '.features[0].properties.headline' | awk '{print $1 " " $2}')
    echo "$HEADLINE" > "$CONDITIONS_FILE"  # Write to conditions file
else
    # No severe alerts
    echo "" > "$ALERT_FILE"           # Set ALERT to False
    # Optionally clear conditions or leave it as is
    # echo "" > "$CONDITIONS_FILE"         # Uncomment to clear conditions if no alert
fi

