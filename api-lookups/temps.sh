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

DTE=`date +%Y-%m-%d`
DTET=`date --date="tomorrow" +%Y-%m-%d`
APIURL="https://api.weather.gov/gridpoints/LWX/35,25/forecast"
LOGFILE="/home/riley/api-lookups/localdata/temps.log"
MAXFORE="/home/riley/api-lookups/localdata/max"
MINFORE="/home/riley/api-lookups/localdata/min"
LMAXFORE="/home/riley/api-lookups/localdata/lastmax"
LMINFORE="/home/riley/api-lookups/localdata/lastmin"
LCURTEMP="/home/riley/api-lookups/localdata/lcurtemp"
CURTEMP="/home/riley/api-lookups/localdata/curtemp"


HItempT=`curl -s $APIURL | grep -A 5 "Today" | grep "temperature\"" | awk -F":" '{print $2}' | sed 's/ //g' | sed 's/,//g'`
LOWtempT=`curl -s $APIURL | grep -A 5 "Tonight" | grep "temperature\"" | awk -F":" '{print $2}' | sed 's/ //g' | sed 's/,//g'`
if [ -n "$HItempT" ]; then
  echo "$HItempT" > $MAXFORE
  echo "$HItempT" > $LMAXFORE
else
  cat $LMAXFORE > $MAXFORE
fi
if [ -n "$LOWtempT" ]; then
  echo "$LOWtempT" > $MINFORE
  echo "$LOWtempT" > $LMINFORE
else
  cat $LMINFORE > $MINFORE
fi

URL='https://api.weather.gov/stations/KW13/observations/latest'
temp_c=`curl -s $URL | grep -A 5  "temperature" | grep value | awk -F":" '{print $2}' | sed 's/,//g' | sed 's/ //g'`

temp_f=`echo "$temp_c * 9 / 5 + 32" | bc`

if [ -n "$temp_f" ]; then
	echo $temp_f > $CURTEMP
	echo $temp_f > $LCURTEMP
 else
	cat $LCURTEMP > $CURTEMP
fi

echo "`date "+%m%d%y_%H:%M"`|CUR:`cat $CURTEMP`|MAX:`cat $MAXFORE`|MIN:`cat $MINFORE`"  >> $LOGFILE
