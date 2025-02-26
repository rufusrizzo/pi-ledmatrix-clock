#!/bin/bash
#This script will pull the max/min temps for tomorrow.
#The NOAA temperature forecast for the current day is unreliable to pull.
#I suggest running this around 23:00 for tomorrows temps
#It's not great, but will work over time
#
#Get Noaa data for Waynesboro, VA
#To find your NOAA grid run, with your LAT/Long:
#https://api.weather.gov/points/38.0684,-78.8899
#To find out your local weather station run:
#https://api.weather.gov/gridpoints/LWX/35,25/stations
#
#
#I think this is where I signed up for an API key, https://www.weatherapi.com/signup.aspx


DTE=`date +%Y-%m-%d`
DTET=`date --date="tomorrow" +%Y-%m-%d`
WORKDIR="/home/riley"
APIURL='https://api.weather.com/v2/pws/observations/current?stationId=KVAWAYNE72&format=json&units=e&apiKey=Key'
#APIURL='https://api.weather.com/v2/pws/observations/current?stationId=<LOCAL Station>&format=json&units=e&apiKey=<API KEY>'
APITEMPFL="/tmp/localinfo"
LOGFILE="$WORKDIR/api-lookups/localdata/temps.log"
LCURTEMP="$WORKDIR/api-lookups/localdata/lcurtemp"
CURTEMP="$WORKDIR/api-lookups/localdata/curtemp"
LCURHUM="$WORKDIR/api-lookups/localdata/lrhum"
CURHUM="$WORKDIR/api-lookups/localdata/rhum"
LCURDP="$WORKDIR/api-lookups/localdata/lcurdp"
CURDP="$WORKDIR/api-lookups/localdata/curdp"
#Setting MQTT parameters
MQTTENA="True"
MQTTBROKER="192.168.1.202"
MQTTTOPIC="weather/temp/"
MQTTTOPIC2="weather/observed/"


#temp_c=`curl -s $URL | grep -A 5  "temperature" | grep value | awk -F":" '{print $2}' | sed 's/,//g' | sed 's/ //g'`

#temp_f=`echo "$temp_c * 9 / 5 + 32" | bc`
curl -s $APIURL > $APITEMPFL
temp_f=`cat $APITEMPFL | awk -F":" '{print $23}' | awk -F"," '{print $1}'`
humi=`cat $APITEMPFL | awk -F":" '{print $20}' | awk -F"," '{print $1}'`
dewpnt=`cat $APITEMPFL | awk -F":" '{print $25}' | awk -F"," '{print $1}'`


if [ -n "$temp_f" ]; then
	echo $temp_f > $CURTEMP
	echo $temp_f > $LCURTEMP
 else
	cat $LCURTEMP > $CURTEMP
fi
if [ -n "$humi" ]; then
	echo $humi > $CURHUM
	echo $humi > $LCURHUM
 else
	cat $LCURHUMI > $CURHUM
fi
if [ -n "$dewpnt" ]; then
	echo $dewpnt > $CURDP
	echo $dewpnt > $LCURDP
 else
	cat $LCURDP > $CURDP
fi
#Putting the data in the logfile
echo "`date "+%m%d%y_%H:%M"`|CUR:`cat ${CURTEMP}`|HUM:`cat ${CURHUM}`|DEWPNT:`cat ${CURDP}`"  >> $LOGFILE
#If MQTT is enabled, putting data there
if [[ "$MQTTENA" == "True" ]]
	then
		mosquitto_pub -h $MQTTBROKER -r -t "${MQTTTOPIC}CURRENT" -m "`cat ${CURTEMP}`"
		mosquitto_pub -h $MQTTBROKER -r -t "${MQTTTOPIC2}HUMIDITY" -m "`cat ${CURHUM}`"
		mosquitto_pub -h $MQTTBROKER -r -t "${MQTTTOPIC2}DEWPNT" -m "`cat ${CURDP}`"
	else
		echo "MQTT Is disabled"
fi
