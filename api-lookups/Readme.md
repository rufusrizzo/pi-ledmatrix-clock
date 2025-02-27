# Weather Data Fetching Scripts

## Overview
This repository contains two Bash scripts for retrieving weather data:

1. **`wu-temps.sh`** - Fetches current temperature, humidity, and dew point from Weather Underground.
2. **`wu-forecast.sh`** - Fetches the 5-day weather forecast, including high/low temperatures and severe weather conditions.

Both scripts log data to files and publish updates to an MQTT broker if enabled.

## Prerequisites
Before running the scripts, ensure you have:
- **API Key**: Obtain one from [WeatherAPI](https://www.weatherapi.com/signup.aspx).
- **`curl`**: Installed for making API requests.
- **`jq`**: Installed for parsing JSON data.
- **`mosquitto_pub`**: Installed if you plan to use MQTT for data distribution.

## Installation
These scripts run from CRON.

If you want your clock to read the files you need to run this on your clock.

You can run this and put the info in a MQTT topic and clocks can read from the MQTT topic.

   ```
2. Make the scripts executable:
   ```bash
   chmod +x wu-temps.sh wu-forecast.sh
   ```
3. Edit the scripts to insert your API key:
   - Replace `<API KEY>` with your actual Weather Underground API key.
   - The scripts have instructions to set your location, I think.

## Usage

### `wu-temps.sh`
Fetches and logs the current temperature, humidity, and dew point.
```bash
./wu-temps.sh
```
This script:
- Retrieves weather data for Waynesboro, VA (or your configured location).
- Logs temperature, humidity, and dew point to `/tmp/localinfo` and a log file.
- Publishes data to MQTT if enabled.

### `wu-forecast.sh`
Fetches the 5-day forecast and logs max/min temperatures along with severe weather conditions.
```bash
./wu-forecast.sh
```
This script:
- Retrieves a 5-day weather forecast.
- Extracts high/low temperatures and significant weather events.
- Logs forecasted temperatures and conditions.
- Publishes data to MQTT if enabled.

### `clock-custom-alert.sh`
This script interacts with an MQTT broker to monitor and publish weather condition alerts. The script subscribes to a source MQTT topic, moves the existing condition to a backup topic, and allows the user to send a custom weather alert or clear an existing alert.

- Subscribes to a specified MQTT topic for current weather conditions.
- Publishes old weather conditions to a backup topic before updating.
- Sends a custom weather alert message to an alert topic.
- Provides an option to clear existing alerts and restore the last known condition.
- Supports MQTT authentication (optional, can be enabled by adding credentials).
#### Usage
Run the script with a custom alert message:

```sh
./clock-custom-alert.sh "Severe Thunderstorm Warning"
```

To clear an existing alert:

```sh
./clock-custom-alert.sh clear
```

For help:

```sh
./clock-custom-alert.sh -h
```

#### How It Works
1. The script subscribes to the `SOURCE_TOPIC` and retrieves the current weather condition.
2. The old condition is published to `TARGET_TOPIC` for backup.
3. If an alert message is provided, it publishes the alert to `ALERT_TOPIC` and updates the source topic.
4. If `clear` is provided as an argument, it clears the alert and restores the last known condition.



## Configuration
Modify the following variables in both scripts as needed:
- `APIURL`: Update with your location’s API URL.
- `MQTTENA`: Set to `True` to enable MQTT publishing, `False` to disable.
- `MQTTBROKER`: Change to your MQTT broker’s IP.
- `LOGFILE`: Adjust the log file path as needed.

## Scheduling with Cron
To automate script execution, add cron jobs:
```bash
crontab -e
```
Example cron jobs:
```
# Fetch temperature every 30 minutes
*/30 * * * * /path/to/wu-temps.sh

# Fetch forecast daily at 23:00
0 23 * * * /path/to/wu-forecast.sh
```

## Troubleshooting
- Ensure `curl`, `jq`, and `mosquitto_pub` are installed.
- Check API response using:
  ```bash
  curl -s "https://api.weather.com/...&apiKey=<YOUR_API_KEY>"
  ```
- Verify MQTT broker connectivity using:
  ```bash
  mosquitto_pub -h <MQTTBROKER> -t "test" -m "hello"
  ```

## MQTT Topics
The script listens for the following MQTT topics:
```
weather/temp/CURRENT
weather/temp/HIGH
weather/temp/LOW
weather/temp/HIGH2
weather/temp/LOW2
weather/forecast/THUNDER
weather/forecast/COND
weather/forecast/ADVFORE
weather/observed/HUMIDITY
weather/observed/DEWPNT
weather/ALERT
```
## Data Files Used in the Weather Scripts

The weather scripts (`wu-forecast.sh` and `wu-temps.sh`) interact with various data files to store and process weather-related information. Below is a description of each file and its purpose:

### Temporary API Data Files
- **`/tmp/wu-forecast-out`**: Stores raw JSON output from the Weather API.
- **`/tmp/cond.tmp`**: Extracted weather conditions from the API response.
- **`/tmp/cond.json`**: JSON file containing the detailed weather forecast conditions.
- **`/tmp/advweather`**: Stores weather advisories extracted from the API.
- **`/tmp/localinfo`**: Contains temperature and humidity data retrieved from a personal weather station.

### Persistent Weather Data Files
- **`localdata/temps.log`**: A log file storing historical weather data including temperatures, conditions, and advisories.
- **`localdata/max`**: Stores the forecasted maximum temperature for tomorrow.
- **`localdata/min`**: Stores the forecasted minimum temperature for tomorrow.
- **`localdata/max2`**: Stores the highest predicted temperature over the 5-day forecast.
- **`localdata/min2`**: Stores the lowest predicted temperature over the 5-day forecast.
- **`localdata/lastmax`**: Last recorded maximum temperature.
- **`localdata/lastmin`**: Last recorded minimum temperature.
- **`localdata/lcurtemp`**: Stores the last observed temperature.
- **`localdata/curtemp`**: Stores the current observed temperature.
- **`localdata/lrhum`**: Last recorded relative humidity.
- **`localdata/rhum`**: Current relative humidity.
- **`localdata/lcurdp`**: Last recorded dew point.
- **`localdata/curdp`**: Current dew point.

### Weather Condition and Alert Files
- **`localdata/thunder`**: Stores the severity level of Lightning strikes.
- **`localdata/conditions`**: Stores the textual description of weather conditions.
- **`localdata/conditions_old`**: Stores the previous day's weather conditions for comparison.
- **`localdata/advforecast`**: Stores adverse weather events over the next 5 days.
- **`localdata/ALERT`**: Stores active severe weather alerts retrieved from NOAA.
- **`localdata/alert-<date>.txt`**: Stores NOAA weather alerts for a specific date.

### MQTT Data Publishing
The scripts also publish weather data to MQTT topics if enabled. The following files store data that is published:
- **`weather/temp/CURRENT`**: Current observed Temperature.
- **`weather/temp/HIGH`**: Published maximum temperature forecast.
- **`weather/temp/LOW`**: Published minimum temperature forecast.
- **`weather/temp/HIGH2`**: Published maximum 5-day temperature forecast.
- **`weather/temp/LOW2`**: Published minimum 5-day temperature forecast.
- **`weather/forecast/THUNDER`**: Published Lightning severity indicator, I guess Lightning was too long for me...
- **`weather/forecast/COND`**: Published current weather conditions.
- **`weather/forecast/ADVFORE`**: Published 5-day Adverse forecast.

These data files help manage weather information for display on external devices, logging purposes, and integration with MQTT for remote monitoring.




## License
This project is open-source and licensed under the GNU General Public License v3.0 (GPLv3). See the LICENSE file for more details.

## Author
Maintained by RileyC, started on 2/20/2023.




