from typing import Literal, Tuple, TextIO
import serial
import time
import struct

class InvertedPendulum:
    """Interfaccia che astrae l'interazione tramite seriale per il controllo e configurazione del pendolo inverso.
    """

    ser: serial.Serial
    _gather_mode: Literal["BIN", "TEXT"]

    def __init__(self, comport: str):
        self.ser = serial.Serial(baudrate=115200)
        self.ser.port = comport
        self.ser.timeout = .5
        self._gather_mode = "BIN"
    
    def connect(self) -> bool:
        """
        Prova a stabilire la connessione su sreiale con il pendolo.
        Restituisce True se ha successo.
        """
        try:
            self.ser.open()
            return True
        except serial.SerialException as e:
            print(f"Impossibile aprire seriale su porta: {self.ser.port}")
            return False
    
    def gather_data(self, mode: Literal["BIN", "TEXT"] = "BIN") -> None:
        """
        Abilità l'invio dello stato nella modalità predefinità
        """
        self._gather_mode = mode
        self.send_command("debug OFF")
        time.sleep(.25)
        match mode:
            case "BIN":
                self.send_command("gather-data ONBIN")
            case "TEXT":
                self.send_command("gather-data ON")
            case _:
                raise ValueError(f"Invalid data gathering option: {mode}")

    def read_state(self) -> Tuple[float] | None:
        """
        Preleva e decodifica un eventuale pacchetto di stato ricevuto tramite seriale nel buffer.
        Nessuna garanzia che il pacchetto sia effettivamente l'ultimo ricevuto, potrebbe essere il 
        primo di una coda. Chiama il più rapidamente possibile.
        """
        try:
            if self._gather_mode == "BIN":
                linebin: bytes =  self.ser.read_until(expected='-S\r\n'.encode('UTF-8'))
                return self._decode_packet_bin(linebin)
            
            elif self._gather_mode == "TEXT":
                line = self.ser.readline()
                return (float(val) for val in line.decode().split(","))
            
        except serial.SerialException:
            print("No state packet were available")
            return None

    def set_mode(self, mode: Literal["PID", "SF"]) -> None:
        """
        Imposta la modalità del controllore.
        """
        match mode:
            case "PID":
                self.send_command("set-mode PID")
            case "SF":
                self.send_command("set-mode SF")
            case _:
                raise ValueError(f"Invalid controller mode: {mode}")
    
    def set_target(self, target: float) -> None:
        """
        Imposta il target per i controllori che lo supportano.
        """
        self.send_command(f"set-target {target}")

    def send_command(self, command: str) -> bool:
        """
        Astrae l'invio di comandi al pendolo direttamente su seriale.
        Resituisce True se l'invio su seriale non solleva eccezioni.
        """
        try:
            self.ser.write((command + "\n").encode())
            return True
        except serial.SerialException as e:
            return False

    @staticmethod
    def _decode_packet_bin(linebin: bytes) -> Tuple[float] | None:
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
            return (timestamp, u, theta, theta_dot, pos, vel)
        
        except struct.error as e:
            return None

    def clear_serial(self) -> None:
        """Svuota il buffer di ricezione seriale. 
        """
        self.ser.reset_input_buffer()

    @staticmethod
    def save_state_to_file(state: Tuple[float], f: TextIO) -> None:
        """
        Prende una tupla di stato e la aggiunge formattata come nuova riga in un file csv aperto.
        """
        line = ", ".join([str(val) for val in state])
        f.write(line + "\n")