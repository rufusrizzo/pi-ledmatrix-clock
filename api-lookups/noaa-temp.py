
import json
import requests

#Get Noaa data for Waynesboro, VA
#To find out your local weather station run:
#https://api.weather.gov/gridpoints/LWX/35,25/stations
#To find your NOAA grid run, with your LAT/Long:
#https://api.weather.gov/points/38.0684,-78.8899
#
#The below URL get's the latest observed conditions
#I need to save the last temp in case NOAA returns a null
r = requests.get('https://api.weather.gov/stations/KW13/observations/latest')
noaa_json = r.json()

ctemp_c = int(noaa_json['properties']['temperature']['value'])

ctemp_f  = format((ctemp_c *9/5) + 32, ".0f")
print(ctemp_f)
