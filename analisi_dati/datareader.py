import serial
import time
import struct
from datetime import datetime
import random
import pygame

pygame.init()
pygame.joystick.init()

#joypad = pygame.joystick.Joystick(0)

now = datetime.now()
datetime_string = now.strftime("%d-%m-%Y_h%H-%M-%S")
FILENAME = f"SESSION_{datetime_string}.csv"
print("Using file:", FILENAME)

ser = serial.Serial("COM8", baudrate=115200)

ser.timeout = .5

def save_state_line(linebin: bytes, f):
    global pos
    # se non trova l'identificatore univoco per le trasmissioni dello stato, non acquisisce
    if linebin[0:2] != "S-".encode():
        print(f"Invalid starting symbol found: {linebin[0:2]}")
        return
    
    linebin = linebin[2:]
    try:
        timestamp = int.from_bytes(linebin[0:4], "little", signed=False)
        u = struct.unpack('<f', linebin[4:8])[0]
        theta = struct.unpack('<d', linebin[8:16])[0]
        theta_dot = struct.unpack('<d', linebin[16:24])[0]
        pos = struct.unpack('<d', linebin[24:32])[0]
        vel = struct.unpack('<d', linebin[32:40])[0]
        line: str = ", ".join([str(item) for item in (timestamp, u, theta, theta_dot, pos, vel)])
        print(timestamp, u, theta, theta_dot, pos, vel)
        f.write(line + "\n")
    except struct.error as e:
        pass
        #print(e)


def save_line_bin(f):
    line = ser.read_until(expected='-S\r\n'.encode('UTF-8'))
    save_state_line(line, f)

def save_line_txt(f):
    line = ser.readline()
    f.write(line.decode())

time.sleep(2)
print("Abilitando la trasmissione dello stato su seriale...")
#ser.write("offset .08\n".encode())
time.sleep(1)
ser.write("debug OFF\n".encode())
time.sleep(.5)
ser.write("gather-data ONBIN\n".encode())


x = 0
next_x = random.randrange(500, 1000)
target = 0
wanted_target = 0
pos = 0

with open(FILENAME, "a") as f:
    date = now.strftime("%Y-%m-%d %H:%M:%S")
    #f.write(f"===== SESSION: {date} =====\n")
    f.write(f"timestamp,\tinput,\ttheta,\ttheta_dot,\tpos,\tvel\n")
    print("Entrando nel loop...")
    time.sleep(2)
    ser.reset_input_buffer()
    while True:
        pygame.event.get()
        
        #wanted_target += joypad.get_axis(0) * 5
        #target += (wanted_target - target) * .01
        #ser.write(f"set-target {target}\n".encode())
        
        save_line_bin(f)
        #time.sleep(0.009)