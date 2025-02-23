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
#This kinda worked, but I had issues, I switched to Weather Underground

DTE=`date +%Y-%m-%d`
DTET=`date --date="tomorrow" +%Y-%m-%d`
APIURL="https://api.weather.gov/gridpoints/LWX/35,25/forecast"
OUTFILE="localdata/fc-temps"
LASTFILE="localdata/fc-temps-last"

HItempT=`curl -s $APIURL | grep -A 3 "\"startTime\": \"$DTET" | grep -i "temperature" | sed 's/,//g' | awk '{print $2}' | head -1`
LOWtempT=`curl -s $APIURL | grep -A 3 "\"startTime\": \"$DTET" | grep -i "temperature" | sed 's/,//g' | awk '{print $2}' | tail -1`
[[ ! -z "$HItempT" ]] && [ ! -z "$LOWtempT" ] && cp $OUTFILE $LASTFILE
echo "Hi: $HItempT" > $OUTFILE
echo "Low: $LOWtempT" >>$OUTFILE

