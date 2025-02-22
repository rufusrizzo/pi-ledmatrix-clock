import json
from rgbmatrix import RGBMatrix, RGBMatrixOptions, graphics
from datetime import datetime
import time
import paho.mqtt.client as mqtt

#Play with pos_x and pos_y to change where the time is on the matrix
#To change the color adjust the RGB values defined in text_color
#The fonts are a pain in the butt, I've included the basic ones that work for me in the "fonts" directory.
#I got the fonts from rpi-rgb-led-matrix


# Debug flag
DEBUG = False

# Initialize the RGB matrix with 16x32 configuration
def init_matrix():
    options = RGBMatrixOptions()
    options.rows = 16
    options.cols = 32
    options.chain_length = 1
    options.parallel = 1
    options.hardware_mapping = "regular"  # Adjust if needed
    options.brightness = 50
    return RGBMatrix(options=options)

# MQTT Configuration
MQTT_BROKER = "192.168.1.202"
TOPICS = ["weather/temp/HIGH", "weather/temp/LOW", "weather/temp/CURRENT"]

# Store latest MQTT values (as numbers)
mqtt_data = {
    "weather/temp/HIGH": None,
    "weather/temp/LOW": None,
    "weather/temp/CURRENT": None
}

def parse_mqtt_payload(payload):
    """Parses the MQTT payload to extract an integer value."""
    try:
        # Try parsing as JSON
        data = json.loads(payload)
        if isinstance(data, dict) and "value" in data:
            return int(float(data["value"]))  # Ensure conversion to int
        elif isinstance(data, (int, float)):  # If it's a direct number
            return int(float(data))  # Convert to int
    except json.JSONDecodeError:
        # If it's not JSON, try converting it directly
        try:
            return int(float(payload))  # Convert to int
        except ValueError:
            return None  # Invalid data

def on_connect(client, userdata, flags, rc):
    if DEBUG:
        print(f"Connected to MQTT broker with result code {rc}")
    for topic in TOPICS:
        client.subscribe(topic)
        if DEBUG:
            print(f"Subscribed to {topic}")

def on_message(client, userdata, msg):
    """Handles incoming MQTT messages."""
    payload = msg.payload.decode("utf-8")
    value = parse_mqtt_payload(payload)
    mqtt_data[msg.topic] = value

    if DEBUG:
        print(f"MQTT Update: {msg.topic} = {payload} (Parsed: {value})")

# Set up MQTT client
client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message
client.connect(MQTT_BROKER, 1883, 60)
client.loop_start()

# Allow some time for MQTT connection
time.sleep(2)

# Draw the time on the matrix
def draw_time(matrix):
    canvas = matrix.CreateFrameCanvas()
    font = graphics.Font()
    font.LoadFont("fonts/6x9.bdf")  # Small font for 16x32 display
    font2 = graphics.Font()
    font2.LoadFont("fonts/4x6.bdf")  # Small font for 16x32 display
    text_color = graphics.Color(255, 0, 0)  # Red text
    text_colory = graphics.Color(255, 255, 0)  # Yellow text
    text_colorg = graphics.Color(0, 255, 0)  # Green text
    text_colorb = graphics.Color(0, 0, 255)  # Blue text
    pos_x = 1  # X position for the text
    pos_y = 7  # Y position for the text
    pos_xx = 1  # X position for the text
    pos_yy = 16  # Y position for the text

    while True:
        canvas.Clear()
        current_time = datetime.now().strftime("%H:%M")
        graphics.DrawText(canvas, font, pos_x, pos_y, text_color, current_time)

        # Convert values to strings, handling None values gracefully
        current_temp = f"{int(mqtt_data['weather/temp/CURRENT'])}" if mqtt_data['weather/temp/CURRENT'] is not None else "--"
        high_temp = f"{int(mqtt_data['weather/temp/HIGH'])}" if mqtt_data['weather/temp/HIGH'] is not None else "--"
        low_temp = f"{int(mqtt_data['weather/temp/LOW'])}" if mqtt_data['weather/temp/LOW'] is not None else "--"

        graphics.DrawText(canvas, font2, pos_xx, pos_yy, text_colorg, current_temp)
        graphics.DrawText(canvas, font2, pos_xx+11, pos_yy, text_color, high_temp)
        graphics.DrawText(canvas, font2, pos_xx+22, pos_yy, text_colorb, low_temp)

        if DEBUG:
            print(f"Displaying: Current={current_temp}, High={high_temp}, Low={low_temp}")
            print(f"mqtt_data['weather/temp/CURRENT']")

        canvas = matrix.SwapOnVSync(canvas)
        time.sleep(1)  # Update every second

if __name__ == "__main__":
    matrix = init_matrix()
    draw_time(matrix)

