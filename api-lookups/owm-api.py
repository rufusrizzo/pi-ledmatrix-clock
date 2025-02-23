
import json
import requests
#localvars.json example
#{
#"var1":1,
#"var2":1.2,
#"var3":1.3,
#"apikey": "KEYkeyKEYkey"
#}
# read local vars file
with open('localvars.json', 'r') as myfile:
    data=myfile.read()
# parse file
obj = json.loads(data)
# set keyvar
owmapikey = obj['apikey']


url = "https://api.openweathermap.org/data/2.5/weather?zip=22980,US&appid=%s&units=imperial" % owmapikey

r = requests.get(url)
owm_json = r.json()

owmw = owm_json['main']

temp = owmw['temp']
#tempf  = 9/5*(temp - 273) + 32 
#temp_f = int(format(tempf , ".0f"))
temp_f = int(format(temp , ".0f"))
temp_max = owmw['temp_max']
#tempf_max  = 9/5*(temp_max - 273) + 32 
#temp_f_max = int(format(tempf_max , ".0f"))
temp_f_max = int(format(temp_max , ".0f"))
temp_min = owmw['temp_min']
#tempf_min  = 9/5*(temp_min - 273) + 32 
#temp_f_min = int(format(tempf_min , ".0f"))
temp_f_min = int(format(temp_min , ".0f"))

print("Temp")
print(temp_f)
print("Temp Max")
print(temp_f_max)
print("Temp Min")
print(temp_f_min)
