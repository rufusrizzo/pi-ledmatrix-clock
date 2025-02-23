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

## License
This project is open-source and licensed under the GNU General Public License v3.0 (GPLv3). See the LICENSE file for more details.

## Author
Maintained by RileyC, started on 2/20/2023.




