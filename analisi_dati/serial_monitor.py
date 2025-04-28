from typing import Callable
import serial
import threading

def default_handler(data: bytes):
    print(data.decode())

class SerialMonitor:
    listen: threading.Event
    lock: threading.Lock
    recv_handler: Callable[[bytes], Any] = default_handler
    ser: serial.Serial

    def __init__(self, ser: serial.Serial):
        self.ser = ser
        self.listen = threading.Event()
        self.lock = threading.Lock()

    def set_recv_handler(self, handler: Callable[[bytes], Any]):
        self.recv_handler = handler

    def begin(self):
        t = threading.Thread(target=self.threaded_recv)
        t.start()

    def _threaded_recv(self):
        self.ser.timeout = 0
        print("entering recv thread")

        while self.listen.is_set():
            data: bytes = self.ser.readline()
            with self.lock:
                self.recv_handler(data)

        print("exiting recv thread")

    def input_message(self):
        user_input = input("Enter a serial message:") + "\n"
        with self.lock:
            self.ser.write(user_input.encode())
            print(f"message sent: {user_input}")


ser = serial.Serial(port="COM4", baudrate=115200)
monitor = SerialMonitor(ser)
monitor.begin()

while True:
    monitor.input_message()
