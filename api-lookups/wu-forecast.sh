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
#I think this is where I signed up for an API key, https://www.weatherapi.com/signup.aspx

DTE=`date +%Y-%m-%d`
DTET=`date --date="tomorrow" +%Y-%m-%d`
WORKDIR="/home/riley"
APIURL='https://api.weather.com/v3/wx/forecast/daily/5day?geocode=38.06,-78.88&format=json&units=e&language=en-US&apiKey=<API KEY>'
#APIURL='https://api.weather.com/v3/wx/forecast/daily/5day?geocode=<LAT,LONG>&format=json&units=e&language=en-US&apiKey=<API KEY>'
LOGFILE="$WORKDIR/api-lookups/localdata/temps.log"
MAXFORE="$WORKDIR/api-lookups/localdata/max"
MINFORE="$WORKDIR/api-lookups/localdata/min"
MAXFORE2="$WORKDIR/api-lookups/localdata/max2"
MINFORE2="$WORKDIR/api-lookups/localdata/min2"
LMAXFORE="$WORKDIR/api-lookups/localdata/lastmax"
LMINFORE="$WORKDIR/api-lookups/localdata/lastmin"
LCURTEMP="$WORKDIR/api-lookups/localdata/lcurtemp"
CURTEMP="$WORKDIR/api-lookups/localdata/curtemp"
THUNDERCAST="$WORKDIR/api-lookups/localdata/thunder"
CONDFORE="$WORKDIR/api-lookups/localdata/conditions"
ADVFORE="$WORKDIR/api-lookups/localdata/advforecast"
APIFILE="/tmp/wu-forecast-out"
CONDTEMP="/tmp/cond.tmp"
CONDJSON="/tmp/cond.json"
ADVWEATHERFILE="/tmp/advweather"
#MQTT Setup, the topics are used by other clock/scripts.  
MQTTENA="True"
MQTTBROKER="192.168.1.202"
MQTTTOPIC="weather/temp/"
MQTTTOPIC2="weather/observed/"
MQTTTOPIC3="weather/forecast/"


curl -s $APIURL > $APIFILE
cat $APIFILE | jq -r ".narrative" > $CONDJSON

HItempT=`cat $APIFILE | sed 's/\[//g' | awk -F":" '{print $2}' | awk -F"," '{print $1}'`
LOWtempT=`cat $APIFILE | sed 's/\[//g' | awk -F":" '{print $3}' | awk -F"," '{print $1}'`
HItempT2=$(for i in `cat $APIFILE  | sed 's/\[//g' | awk -F":" '{print $2}' | awk -F"]" '{print $1}' | sed 's/,/ /g'`
	do
	echo $i
done | sort -g  | tail -1 )
LOWtempT2=$(for i in `cat $APIFILE  | sed 's/\[//g' | awk -F":" '{print $3}' | awk -F"]" '{print $1}' | sed 's/,/ /g'`
	do
	echo $i
done | sort -g  | head -1 )
THUNDER=`cat $APIFILE | sed 's/\[//g' | awk -F":" '{print $103}' | awk -F"," '{print $2}'`
cat $APIFILE | grep -Po '"wxPhraseLong":.*?[^\\]",' | awk -F"\"" '{print $4}' > $CONDTEMP
CONDITIONS=`cat $CONDTEMP`
#Ok I'm going a little crazy, I'm check for upcoming Rain or snow and setting and array for which day may have them.
#Now I'm having to learn how to deal with JSON

unset arrVar
unset DAYNUM
unset ADVWEATHER
#
#This is looking for these conditions in the forcast data.
#If it is in the forecast it will remember the day it's forcasted for a quick/short way to show when bad weather is coming
DAYNUM=0
cat $CONDJSON | while IFS= read -r line
	do RIF=`echo $line | sed 's/"//g' | sed 's/,//g' | egrep -i "rain|snow|storm|ice|tornado|nado|thunder"`
	if [ -n "$RIF" ] ; then  arrVar+=("$DAYNUM") ; fi
	ADVWEATHER="${arrVar[@]}"
	let DAYNUM=$DAYNUM+1
	echo $ADVWEATHER > $ADVWEATHERFILE
done
#Setting the Max and Min temps, I had problems getting the forecast, so I set a Last Max/Min Forecasted Temp
if [ -n "$HItempT" ]; then
  echo "$HItempT" > $MAXFORE
  echo "$HItempT2" > $MAXFORE2
  echo "$HItempT" > $LMAXFORE
else
  cat $LMAXFORE > $MAXFORE
fi
if [ -n "$LOWtempT" ]; then
  echo "$LOWtempT" > $MINFORE
  echo "$LOWtempT2" > $MINFORE2
  echo "$LOWtempT" > $LMINFORE
else
  cat $LMINFORE > $MINFORE
fi

#This sets the severity/chance of Lightning to display on the clock
case $THUNDER in 
	0) echo '_' > $THUNDERCAST ;;
	1) echo '|' > $THUNDERCAST ;;
	2) echo '||' > $THUNDERCAST ;;
	3) echo '|||' > $THUNDERCAST ;;
	4) echo '||||' > $THUNDERCAST ;; 
	5) echo '|||||' > $THUNDERCAST ;;
	*) echo '???' > $THUNDERCAST ;;
esac

if [ -n "$CONDITIONS" ]; then
	echo $CONDITIONS > $CONDFORE
fi
ADVWEATHER=`cat $ADVWEATHERFILE`
if [ -n "$ADVWEATHER" ]; then
	echo $ADVWEATHER > $ADVFORE
		else
	echo "Clear" > $ADVFORE
fi

#Putting the data in the logfile
echo "`date "+%m%d%y_%H:%M"`|THUNDER:`cat $THUNDERCAST`,$THUNDER|MAX:`cat $MAXFORE`|MIN:`cat $MINFORE`|MAX2:`cat $MAXFORE2`|MIN2:`cat $MINFORE2`|COND:`cat $CONDFORE`|ADVFORE:`cat $ADVFORE`"  >> $LOGFILE
#If MQTT is enabled, putting data there
if [[ "$MQTTENA" == "True" ]]
	then
		mosquitto_pub -h $MQTTBROKER -r -t "${MQTTTOPIC}HIGH" -m "`cat ${MAXFORE}`"
		mosquitto_pub -h $MQTTBROKER -r -t "${MQTTTOPIC}LOW" -m "`cat ${MINFORE}`"
		mosquitto_pub -h $MQTTBROKER -r -t "${MQTTTOPIC}HIGH2" -m "`cat ${MAXFORE2}`"
		mosquitto_pub -h $MQTTBROKER -r -t "${MQTTTOPIC}LOW2" -m "`cat ${MINFORE2}`"
		mosquitto_pub -h $MQTTBROKER -r -t "${MQTTTOPIC3}THUNDER" -m "`cat $THUNDERCAST`,$THUNDER"
		mosquitto_pub -h $MQTTBROKER -r -t "${MQTTTOPIC3}COND" -m "`cat $CONDFORE`"
		mosquitto_pub -h $MQTTBROKER -r -t "${MQTTTOPIC3}ADVFORE" -m "`cat $ADVFORE`"
	else
		echo "MQTT Is disabled"
fi

