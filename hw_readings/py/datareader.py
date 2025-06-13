import time
import math
from datetime import datetime
import random
import pygame

from serial_pendulum import InvertedPendulum

pygame.init()
pygame.joystick.init()

#joypad = pygame.joystick.Joystick(0)

now = datetime.now()
datetime_string = now.strftime("%d-%m-%Y_h%H-%M-%S")
FILENAME = f"SESSION_{datetime_string}.csv"
print("Using file:", FILENAME)

pendolo = InvertedPendulum("COM4")
esito = pendolo.connect()
print("Pendolo connesso: ", esito)
if not esito:
    quit()

time.sleep(3)
print("Abilitando la trasmissione dello stato su seriale...")
pendolo.gather_data("BIN")
time.sleep(.2)
pendolo.send_command("set-pid2 .2 .02 5")
time.sleep(.2)
pendolo.send_command("set-pid1 3000 0 200")
pendolo.set_target(15)

x = 0
next_x = random.randrange(500, 1000)
target = 0
wanted_target = 0
pos = 0

with open(FILENAME, "a") as f:
    # commenti al file csv
    f.write(f"# Date of execution: {now.strftime("%d/%m/%Y at time %H:%M:%S")}\n\n")
    f.write(f"# Controller settings:\n")
    f.write(f"# set-pid2 .2 .02 5\n")
    f.write(f"# set-pid1 3000 0 200\n")

    f.write(f"\ntimestamp, input, theta, theta_dot, pos, vel\n")

    print("Entrando nel loop...")
    pendolo.clear_serial()
    time.sleep(2)
    pendolo.clear_serial()

    i = 0
    while True:
        pygame.event.get()
        
        #wanted_target += joypad.get_axis(0) * 5
        #target += (wanted_target - target) * .01
        i += 1
        if i > 500:
            i = 0
            target = math.sin(time.time() * .3) * 25
            pendolo.set_target(target)
            print("new target: ", target)
        
        state = pendolo.read_state()
        if state:
            print(state)
            pendolo.save_state_to_file(state, f)
        #time.sleep(0.009)
