from rgbmatrix import RGBMatrix, RGBMatrixOptions, graphics
from datetime import datetime
import time
import pytz

# Initialize the RGB matrix with 16x32 configuration
def init_matrix():
    options = RGBMatrixOptions()
    options.rows = 16
    options.cols = 32
    options.chain_length = 1
    options.parallel = 1
    options.hardware_mapping = "regular"  # Adjust if needed
    options.brightness = 10
    return RGBMatrix(options=options)

# Draw the time on the matrix
def draw_time(matrix):
    canvas = matrix.CreateFrameCanvas()
    font = graphics.Font()
    font.LoadFont("fonts/6x9.bdf")  # Small font for 16x32 display
    font2 = graphics.Font()
    font2.LoadFont("fonts/4x6.bdf")  # Small font for 16x32 display
    text_color = graphics.Color(255, 0, 0)  # Yellow text
    text_colorg = graphics.Color(0, 255, 0)  # Green text
    pos_x = 1  # X position for the text
    pos_y = 7  # Y position for the text
    pos_xx = 0  # X position for the text
    pos_yy = 16  # Y position for the text


    while True:
        canvas.Clear()
        current_time = datetime.now().strftime("%H:%M")
        graphics.DrawText(canvas, font, pos_x, pos_y, text_color, current_time)
        current_time = get_gmt_time()
        graphics.DrawText(canvas, font2, pos_xx, pos_yy, text_colorg, current_time)
        canvas = matrix.SwapOnVSync(canvas)
        time.sleep(1)  # Update every second

# Convert Eastern Standard Time (EST) to GMT
def get_gmt_time():
    est = pytz.timezone("America/New_York")  # Eastern Time Z
    gmt = pytz.timezone("GMT")  # GMT Time Zone
    local_time = datetime.now(est)  # Get current time in EST
    gmt_time = local_time.astimezone(gmt)  # Convert to GMT
    return gmt_time.strftime("%H:%M:%S")  # Format as HH:MM:SS



if __name__ == "__main__":
    matrix = init_matrix()
    draw_time(matrix)

