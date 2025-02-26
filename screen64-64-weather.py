import argparse
from rgbmatrix import RGBMatrix, RGBMatrixOptions, graphics
from datetime import datetime, timezone, timedelta
import time
import pytz
from tzlocal import get_localzone
import os
import sys
from pathlib import Path
import paho.mqtt.client as mqtt

# Command-line argument parser
parser = argparse.ArgumentParser(description="LED Matrix Clock")
parser.add_argument("--debug", action="store_true", help="Enable debug output")
parser.add_argument("--data-source", choices=["file", "mqtt"], default="file",
                    help="Data source: 'file' (default) or 'mqtt'")
parser.add_argument("--mqtt-broker", default="localhost", help="MQTT broker hostname (default: localhost)")
parser.add_argument("--mqtt-port", type=int, default=1883, help="MQTT broker port (default: 1883)")
args = parser.parse_args()

# Debug print function
def debug_print(message):
    if args.debug:
        print(f"[DEBUG] {message}")

# Global dictionary to store MQTT data
mqtt_data = {
    "weather/temp/CURRENT": "",
    "weather/temp/HIGH": "",
    "weather/temp/LOW": "",
    "weather/temp/HIGH2": "",
    "weather/temp/LOW2": "",
    "weather/forecast/THUNDER": "",
    "weather/forecast/COND": "",
    "weather/forecast/ADVFORE": "",
    "weather/observed/HUMIDITY": "",
    "weather/observed/DEWPNT": "",
    "weather/ALERT": ""
}

# MQTT Callbacks
def on_connect(client, userdata, flags, rc):
    if rc == 0:
        debug_print("Connected to MQTT broker successfully")
        for topic in mqtt_data.keys():
            client.subscribe(topic)
            debug_print(f"Subscribed to {topic}")
    else:
        debug_print(f"Failed to connect to MQTT broker with code {rc}")

def on_message(client, userdata, msg):
    topic = msg.topic
    payload = msg.payload.decode("utf-8").strip()
    mqtt_data[topic] = payload
    debug_print(f"Received {topic}: {payload}")

# Initialize MQTT client if required
mqtt_client = None
if args.data_source == "mqtt":
    debug_print(f"Setting up MQTT client for broker {args.mqtt_broker}:{args.mqtt_port}")
    mqtt_client = mqtt.Client()
    mqtt_client.on_connect = on_connect
    mqtt_client.on_message = on_message
    try:
        mqtt_client.connect(args.mqtt_broker, args.mqtt_port, 60)
        mqtt_client.loop_start()
        # Wait until we receive at least one message or timeout
        timeout = 10  # Wait up to 10 seconds
        start_time = time.time()
        while time.time() - start_time < timeout:
            if any(mqtt_data.values()):  # Check if any data has been received
                debug_print("Initial MQTT data received, proceeding...")
                break
            debug_print("Waiting for MQTT data...")
            time.sleep(1)
        else:
            debug_print("Timeout: No MQTT data received. Proceeding with defaults.")
    except Exception as e:
        debug_print(f"Error connecting to MQTT broker: {e}")
        sys.exit(1)

# Initialize the RGB matrix with 64x64 configuration
def init_matrix():
    options = RGBMatrixOptions()
    options.rows = 64
    options.cols = 64
    options.chain_length = 1
    options.parallel = 1
    options.hardware_mapping = "adafruit-hat"
    options.brightness = 50
    options.drop_privileges = False
    debug_print("Matrix initialized with 64x64 configuration.")
    matrix = RGBMatrix(options=options)
    canvas = matrix.CreateFrameCanvas()
    return matrix, canvas

# Fetch data based on source
def get_data(variable_name):
    file_paths = {
        "curtemp": '/home/riley/api-lookups/localdata/curtemp',
        "maxtemp": '/home/riley/api-lookups/localdata/max',
        "mintemp": '/home/riley/api-lookups/localdata/min',
        "maxtemp2": '/home/riley/api-lookups/localdata/max2',
        "mintemp2": '/home/riley/api-lookups/localdata/min2',
        "thun": '/home/riley/api-lookups/localdata/thunder',
        "conditions": '/home/riley/api-lookups/localdata/conditions',
        "advweath": '/home/riley/api-lookups/localdata/advforecast',
        "relhum": '/home/riley/api-lookups/localdata/rhum',
        "dewpnt": '/home/riley/api-lookups/localdata/curdp',
        "WeatherAlert": '/home/riley/api-lookups/localdata/ALERT'
    }
    mqtt_topics = {
        "curtemp": "weather/temp/CURRENT",
        "maxtemp": "weather/temp/HIGH",
        "mintemp": "weather/temp/LOW",
        "maxtemp2": "weather/temp/HIGH2",
        "mintemp2": "weather/temp/LOW2",
        "thun": "weather/forecast/THUNDER",
        "conditions": "weather/forecast/COND",
        "advweath": "weather/forecast/ADVFORE",
        "relhum": "weather/observed/HUMIDITY",
        "dewpnt": "weather/observed/DEWPNT",
        "WeatherAlert": "weather/ALERT"
    }

    if args.data_source == "file":
        try:
            return Path(file_paths[variable_name]).read_text().replace('\n', '')
        except Exception as e:
            debug_print(f"Error reading file for {variable_name}: {e}")
            return "N/A"
    elif args.data_source == "mqtt":
        value = mqtt_data[mqtt_topics[variable_name]]
        return value if value else "NA"

# Draw the time on the matrix
def draw_time(matrix, canvas):
    font0 = graphics.Font(); font0.LoadFont("fonts/8x13B.bdf")
    font1 = graphics.Font(); font1.LoadFont("fonts/6x9.bdf")
    font2 = graphics.Font(); font2.LoadFont("fonts/test40.bdf")
    font3 = graphics.Font(); font3.LoadFont("fonts/4x6.bdf")

    dayhour = int(datetime.now().strftime("%H"))
    dayhourstart = 5
    dayhourend = 22

    text_color_red = graphics.Color(255, 0, 0)
    text_color_green = graphics.Color(0, 255, 0)
    text_color_smred = graphics.Color(250, 0, 20)
    text_color_drkgrn = graphics.Color(0, 120, 0)
    text_color_pink = graphics.Color(255, 180, 230)
    text_color_yel = graphics.Color(255, 255, 0)
    text_color_wht = graphics.Color(255, 255, 255)
    text_color_blue = graphics.Color(0, 0, 255)
    text_color_smbl = graphics.Color(0, 120, 255)

    # Fetch data
    curtemp = get_data("curtemp")
    maxtemp = get_data("maxtemp")
    mintemp = get_data("mintemp")
    maxtemp2 = get_data("maxtemp2")
    mintemp2 = get_data("mintemp2")
    thun = get_data("thun")
    conditions = get_data("conditions")
    advweath = get_data("advweath")
    relhum = get_data("relhum")
    dewpnt = get_data("dewpnt")
    WeatherAlert = get_data("WeatherAlert")

    # Debug MQTT data periodically
    if args.data_source == "mqtt" and args.debug and int(time.time()) % 10 == 0:
        debug_print(f"Current MQTT data: {mqtt_data}")
    # Add this debug line to check WeatherAlert value
    debug_print(f"WeatherAlert value: '{WeatherAlert}' (type: {type(WeatherAlert)})")



    pos_x0 = 0
    pos_y_mainclk = 10
    pos_y_date = 18
    pos_y_gmtclk = 26
    pos_y_temp = 34
    pos_y_alert = 41
    pos_y_tempfor = 48
    pos_y_cond = 56
    pos_y_advw = 64

    canvas.Clear()
    current_time = datetime.now().strftime("%H:%M:%S")
    graphics.DrawText(canvas, font0, pos_x0, pos_y_mainclk, text_color_red, current_time)
    weekday = datetime.now().strftime("%a")
    graphics.DrawText(canvas, font1, pos_x0, pos_y_date, text_color_blue, weekday)
    cal = datetime.now().strftime("%b/%d")
    graphics.DrawText(canvas, font1, pos_x0 + 28, pos_y_date, text_color_green, cal)
    
    gmt_time = get_gmt_time()
    graphics.DrawText(canvas, font1, pos_x0, pos_y_gmtclk, text_color_drkgrn, f"{gmt_time}")
    graphics.DrawText(canvas, font1, pos_x0 + 53, pos_y_temp, text_color_pink, curtemp)

    if dayhour >= dayhourstart and dayhour <= dayhourend:
        graphics.DrawText(canvas, font3, pos_x0 + 37, pos_y_gmtclk, text_color_pink, "D")
        graphics.DrawText(canvas, font3, pos_x0 + 41, pos_y_gmtclk, text_color_smbl, dewpnt)
        graphics.DrawText(canvas, font3, pos_x0 + 51, pos_y_gmtclk, text_color_pink, "H")
        graphics.DrawText(canvas, font3, pos_x0 + 56, pos_y_gmtclk, text_color_smbl, relhum)
        graphics.DrawText(canvas, font1, pos_x0 , pos_y_temp, text_color_wht, '~')
        graphics.DrawText(canvas, font1, pos_x0 +1, pos_y_temp, text_color_wht, '~')
        graphics.DrawText(canvas, font1, pos_x0 +2, pos_y_temp, text_color_wht, '~')
        graphics.DrawText(canvas, font1, pos_x0 +2, pos_y_temp +1, text_color_yel, '\ ')
        graphics.DrawText(canvas, font3, pos_x0 + 8, pos_y_temp, text_color_red, thun)
        graphics.DrawText(canvas, font3, pos_x0 + 33, pos_y_temp, text_color_pink, "Temp:")
        graphics.DrawText(canvas, font3, pos_x0, pos_y_tempfor, text_color_red, "Mx:")
        graphics.DrawText(canvas, font3, pos_x0 + 11, pos_y_tempfor, text_color_red, maxtemp)
        graphics.DrawText(canvas, font3, pos_x0 + 18, pos_y_tempfor, text_color_smbl, "|")
        graphics.DrawText(canvas, font3, pos_x0 + 21, pos_y_tempfor, text_color_red, maxtemp2)
        graphics.DrawText(canvas, font3, pos_x0 + 35, pos_y_tempfor, text_color_smbl, "Mn:")
        graphics.DrawText(canvas, font3, pos_x0 + 46, pos_y_tempfor, text_color_smbl, mintemp)
        graphics.DrawText(canvas, font3, pos_x0 + 53, pos_y_tempfor, text_color_red, "|")
        graphics.DrawText(canvas, font3, pos_x0 + 56, pos_y_tempfor, text_color_smbl, mintemp2)
        graphics.DrawText(canvas, font3, pos_x0, pos_y_cond, text_color_pink, conditions)
        graphics.DrawText(canvas, font3, pos_x0, pos_y_advw, text_color_red, "BadWea:")
        graphics.DrawText(canvas, font3, pos_x0 + 28, pos_y_advw, text_color_red, advweath)

    debug_print(WeatherAlert)

    #if WeatherAlert == "alert":  # Exact string comparison
    if str(WeatherAlert).lower() == "alert":
        debug_print("WeatherAlert is Active#######################################################################")
        current_second = int(time.time() % 2) 
        if current_second == 0:
            graphics.DrawText(canvas, font3, pos_x0, pos_y_alert, text_color_red, "* * * * * * * * ")
            graphics.DrawText(canvas, font3, pos_x0, pos_y_alert, text_color_yel, "________________")
        else:
            graphics.DrawText(canvas, font3, pos_x0, pos_y_alert, text_color_wht, " * * * * * * * *")
            graphics.DrawText(canvas, font3, pos_x0, pos_y_alert, text_color_yel, "________________")

    canvas = matrix.SwapOnVSync(canvas)
    time.sleep(1)

def get_gmt_time():
    est = pytz.timezone("America/New_York")
    gmt = pytz.timezone("GMT")
    local_time = datetime.now(est)
    gmt_time = local_time.astimezone(gmt)
    return gmt_time.strftime("%H:%MU")

if __name__ == "__main__":
    debug_print("Starting LED Matrix Clock...")
    matrix, canvas = init_matrix()
    debug_print("Starting the Clock")
    try:
        while True:
            draw_time(matrix, canvas)
    except KeyboardInterrupt:
        if args.data_source == "mqtt" and mqtt_client:
            mqtt_client.loop_stop()
            mqtt_client.disconnect()
            debug_print("MQTT client disconnected")
        debug_print("Clock stopped")

