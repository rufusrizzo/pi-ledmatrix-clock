#!/bin/bash

#Get Noaa data for Waynesboro, VA
#To find out your local weather station run:
#https://api.weather.gov/gridpoints/LWX/35,25/stations
#To find your NOAA grid run, with your LAT/Long:
#https://api.weather.gov/points/38.0684,-78.8899
#
#The below URL get's the latest observed conditions
#I need to save the last temp in case NOAA returns a null
URL='https://api.weather.gov/stations/KW13/observations/latest'
temp_c=`curl -s $URL | grep -A 5  "temperature" | grep value | awk -F":" '{print $2}' | sed 's/,//g' | sed 's/ //g'`

temp_f=`echo "$temp_c * 9 / 5 + 32" | bc`

#echo $temp_c > localdata/bash_noaa_temp
echo $temp_f > localdata/bash_noaa_temp
