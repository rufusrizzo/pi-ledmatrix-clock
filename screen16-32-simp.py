from rgbmatrix import RGBMatrix, RGBMatrixOptions, graphics
from datetime import datetime
import time

#Play with pos_x and pos_y to change where the time is on the matrix
#To change the color adjust the RGB values defined in text_color
#The fonts are a pain in the butt, I've included the basic ones that work for me in the "fonts" directory.
#I got the fonts from rpi-rgb-led-matrix

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

# Draw the time on the matrix
def draw_time(matrix):
    canvas = matrix.CreateFrameCanvas()
    font = graphics.Font()
    font.LoadFont("fonts/5x7.bdf")  # Small font for 16x32 display
    text_color = graphics.Color(255, 0, 0)  # Yellow text
    pos_x = 1  # X position for the text
    pos_y = 6  # Y position for the text

    while True:
        canvas.Clear()
        current_time = datetime.now().strftime("%H:%M")
        graphics.DrawText(canvas, font, pos_x, pos_y, text_color, current_time)
        canvas = matrix.SwapOnVSync(canvas)
        time.sleep(1)  # Update every second

if __name__ == "__main__":
    matrix = init_matrix()
    draw_time(matrix)

