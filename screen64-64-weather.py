import argparse
from rgbmatrix import RGBMatrix, RGBMatrixOptions, graphics
from datetime import datetime, timezone
from datetime import timedelta
import time
import pytz
from tzlocal import get_localzone 
import dill
import multiprocessing
import signal
from six.moves import queue
import os
import sys
from pathlib import Path

# Command-line argument parser
parser = argparse.ArgumentParser(description="LED Matrix Clock")
parser.add_argument("--debug", action="store_true", help="Enable debug output")
args = parser.parse_args()

# Debug print function
def debug_print(message):
    if args.debug:
        print(message)

# Initialize the RGB matrix with 64x64 configuration
def init_matrix():
    options = RGBMatrixOptions()
    options.rows = 64
    options.cols = 64
    options.chain_length = 1
    options.parallel = 1
    options.hardware_mapping = "adafruit-hat"  # Adjust if needed
    options.brightness = 50  # Increased brightness for visibility
    options.drop_privileges = False  # Prevents real-time priority issue
    debug_print("Matrix initialized with 64x64 configuration.")
    matrix = RGBMatrix(options=options)
    canvas = matrix.CreateFrameCanvas()  # Create canvas once here
    return matrix, canvas

# Draw the time on the matrix
def draw_time(matrix, canvas):
    # Load larger fonts for better readability
    font0 = graphics.Font()
    font0.LoadFont("fonts/8x13B.bdf")  # Bigger font for 64x64 display
    font1 = graphics.Font()
    font1.LoadFont("fonts/6x9.bdf")  # Bigger font for 64x64 display
    font2 = graphics.Font()
    font2.LoadFont("fonts/test40.bdf")  # Bigger font for 64x64 display
    font3 = graphics.Font()
    font3.LoadFont("fonts/4x6.bdf")  # Bigger font for 64x64 display

    # Define when clock scales back the output
    dayhour = int(datetime.now().strftime("%H"))
    dayhourstart = 5
    dayhourend = 22

    # Define colors
    text_color_red = graphics.Color(255, 0, 0)  # Red text
    text_color_green = graphics.Color(0, 255, 0)  # Green text
    text_color_smred = graphics.Color(250, 0, 20) 
    text_color_drkgrn = graphics.Color(0, 120, 0)
    text_color_pink = graphics.Color(255, 180, 230)
    text_color_yel = graphics.Color(255, 255, 0)  
    text_color_wht = graphics.Color(255, 255, 255)  
    text_color_blue = graphics.Color(0, 0, 255)  
    text_color_smbl = graphics.Color(0, 120, 255)  

    # Weather Data
    curtemp = Path('/home/riley/api-lookups/localdata/curtemp').read_text().replace('\n', '')
    maxtemp = Path('/home/riley/api-lookups/localdata/max').read_text().replace('\n', '')
    mintemp = Path('/home/riley/api-lookups/localdata/min').read_text().replace('\n', '')
    maxtemp2 = Path('/home/riley/api-lookups/localdata/max2').read_text().replace('\n', '')
    mintemp2 = Path('/home/riley/api-lookups/localdata/min2').read_text().replace('\n', '')
    thun = Path('/home/riley/api-lookups/localdata/thunder').read_text().replace('\n', '')
    conditions = Path('/home/riley/api-lookups/localdata/conditions').read_text().replace('\n', '')
    advweath = Path('/home/riley/api-lookups/localdata/advforecast').read_text().replace('\n', '')
    relhum = Path('/home/riley/api-lookups/localdata/rhum').read_text().replace('\n', '')
    dewpnt = Path('/home/riley/api-lookups/localdata/curdp').read_text().replace('\n', '')
    WeatherAlert = Path('/home/riley/api-lookups/localdata/ALERT').read_text().replace('\n', '')

    # Define WeatherAlert condition (example: true if advweath is not empty)
    WeatherAlert = bool(WeatherAlert.strip())  # True if advweath has content, False if empty

    # Adjusted positions
    pos_x0 = 0   # X position for the local time
    pos_y_mainclk = 10  # Y position for the local time (centered)
    pos_y_date = 18  # Y position for the Date
    pos_y_gmtclk = 26  # Y position for the GMT time (centered)
    pos_y_temp = 34  # Y position for the Temp and Lightning
    pos_y_alert = 41  # Y position for the Alert Line
    pos_y_tempfor = 48  # Y position for the Temp Forecast
    pos_y_cond = 56  # Y position for the Conditions
    pos_y_advw = 64  # Y position for the Adverse Weather

    canvas.Clear()
    # Main Clock
    current_time = datetime.now().strftime("%H:%M:%S")
    graphics.DrawText(canvas, font0, pos_x0, pos_y_mainclk, text_color_red, current_time)
    # Day and Date
    weekday = datetime.now().strftime("%a")
    graphics.DrawText(canvas, font1, pos_x0, pos_y_date, text_color_blue, weekday)
    cal = datetime.now().strftime("%b/%d")
    graphics.DrawText(canvas, font1, pos_x0 + 28, pos_y_date, text_color_green, cal)
        
    # GMT Time
    gmt_time = get_gmt_time()
    graphics.DrawText(canvas, font1, pos_x0, pos_y_gmtclk, text_color_drkgrn, f"{gmt_time}")
    # Current Temp
    graphics.DrawText(canvas, font1, pos_x0 + 53, pos_y_temp, text_color_pink, curtemp)

    # Flashing alert when WeatherAlert is True
    if WeatherAlert:
        # Use current time to toggle every half second (since loop is 1s, this approximates)
        current_second = int(time.time() % 2)  # 0 or 1 based on even/odd second
        if current_second == 0:
            graphics.DrawText(canvas, font3, pos_x0, pos_y_alert, text_color_red, "* * * * * * * * ")
            graphics.DrawText(canvas, font3, pos_x0, pos_y_alert, text_color_yel, "________________")
        else:
            graphics.DrawText(canvas, font3, pos_x0, pos_y_alert, text_color_wht, " * * * * * * * *")
            graphics.DrawText(canvas, font3, pos_x0, pos_y_alert, text_color_yel, "________________")
    # If no alert, you could leave it blank or show something else (optional)
    # else:
    #     graphics.DrawText(canvas, font3, pos_x0, pos_y_alert, text_color_wht, "No Alert")

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

    canvas = matrix.SwapOnVSync(canvas)
    time.sleep(1)  # Update every second

# Convert Eastern Standard Time (EST) to GMT
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
    while True:
        draw_time(matrix, canvas)

