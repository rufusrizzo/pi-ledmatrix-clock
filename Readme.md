
# RGB Matrix Clock Display

This project includes Python scripts that display time or temperature information on an RGB LED matrix (16x32). The scripts use the `rpi-rgb-led-matrix` library for controlling the display and MQTT for receiving temperature data.  

## Scripts Overview

- `screen16-32-simp.py` - Displays the local time on the matrix.
- `screen16-32-simp_gmt.py` - Displays both local time and GMT time on the matrix.
- `screen16-32-temp.py` - Displays the local time along with current, high, and low temperature readings received via MQTT.

## Dependencies

### System Dependencies
I assume you can install Raspberry Pi OS on your Raspberry Pi 0w or higher, see the Hardware directory for more info.

Ensure you have installed the required system dependencies:

```bash
sudo apt-get install -y libgraphicsmagick++-dev libwebp-dev libjpeg-dev libpng-dev libtiff-dev libfreetype6-dev
```

Additionally, you may need to install the `rpi-rgb-led-matrix` library:

```bash
git clone https://github.com/hzeller/rpi-rgb-led-matrix.git
cd rpi-rgb-led-matrix
make
sudo make install
```

### Python Dependencies
Install the required Python packages using pip:

```bash
pip install rpi-rgb-led-matrix paho-mqtt pytz
```


## Usage

Run the desired script using Python:

```bash
python3 screen16-32-simp.py
```

or

```bash
python3 screen16-32-simp_gmt.py
```

or

```bash
python3 screen16-32-temp.py
```

The `screen16-32-temp.py` script requires an MQTT broker to be running and publishing temperature data to the following topics:
The topic must be named "value"  
Temp Sample JSON:

```bash
{
  "value": "75"
}

```

- `weather/temp/HIGH`
- `weather/temp/LOW`
- `weather/temp/CURRENT`

The script is configured to connect to an MQTT broker at `192.168.1.202` (modify this as needed in the script).

## Configuration

### Script Tinkering
Play with pos_x and pos_y to change where the time is on the matrix
To change the color adjust the RGB values defined in text_color
The fonts are a pain, I've included the basic ones that work for me in the "fonts" directory.
I got the fonts from rpi-rgb-led-matrix


### Timezone Configuration
The scripts use the `pytz` library to handle timezone conversions. Ensure your system timezone is correctly set, or modify the script to explicitly set a desired timezone. Adjust the timezone in the script using:

```python
import pytz
timezone = pytz.timezone('America/New_York')  # Change to your preferred timezone
```

### Brightness Configuration
The brightness of the LED matrix display can be adjusted by modifying the brightness parameter in the script. Update the script to set the brightness level (0-100):

```python
options.brightness = 50  # Adjust brightness as needed
```

## Font Files
Ensure the required font files (`6x9.bdf`, `5x7.bdf`, and `4x6.bdf`) are available in the `fonts/` directory, as they are used for text rendering on the matrix.

## Hardware Setup
These scripts are designed for use with a 16x32 RGB LED matrix connected to a Raspberry Pi. Adjust `hardware_mapping` in the script as needed to match your setup.

I assume you can install Raspberry Pi OS on your Raspberry Pi.

See Hardware directory for more info.

## ToDo
- [x] Clean up startup script names
- [ ] Document Hardware, including pictures, parts, and wiring
- [x] Add Big Clock scripts 64x64
- [x] Migrate Weather Collection to MQTT
- [ ] Document Big Clock info
- [ ] Add configuration to switch Big clock to files or MQTT
- [ ] Add configuration to switch screen16-32-temp.py between files or MQTT


## License
This project is open-source and licensed under the GNU General Public License v3.0 (GPLv3). See the LICENSE file for more details.

## Author
Maintained by RileyC, started on 2/20/2025.

 Original code by Flavio Fernandes from https://github.com/flavio-fernandes/bedclock, licensed under MIT License
 Adapted for Simplier Code (that I can understand) and displaying data that fits my needs on 2/20/2025.

My Orginal Inspiration came from Lady ada of Adafruit.
https://learn.adafruit.com/adafruit-rgb-matrix-bonnet-for-raspberry-pi?view=all

