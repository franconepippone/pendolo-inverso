#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <espnow.h>

#include "pid.h"
#include "loopclock.h"
#include "cart.h"
#include "microstep_controller.h"
#include "utils.h"

#define LOOPFREQ 100 // Hz
#define LOOP_PERIOD_US 1.0 / LOOPFREQ / MUs_TO_S

#define STEP_PIN        4
#define DIR_PIN         5
#define EN_PIN         14
#define MS1             12
#define MS2             13
#define MS3             15 // be mindful of this pin

#define INPUT_RANGE 1500



PID pid_outer(3, .3, 15); // set-pid2 -5 0 10 //set-pid2 -5 -.2 -10 //set-pid2 -5 -1 -15 ALTERNATIVA PIU AGGRESSIVA
PID pid_inner(10000, 0, 550); //set-pid1 10000 0 250

enum ControllerType { PID, FULL_SF, SPEED };
enum ControllerState { RUNNING, OFF, SKIP };

ControllerState currentState = OFF;
ControllerType currentMode = PID;  

Clock clock_outer;
Clock clock_inner;

PendulumCart cart(EN_PIN, STEP_PIN, DIR_PIN);
A4988microstepController ms_controller(MS1, MS2, MS3);

Vec4 K(-7000,  -600,   -5,   -15); //-7000 -600 -5 -15
numericalIntegrator sf_integral(.3);

// Must match the sender structure
typedef struct sensorPacket {
  double theta;
  double theta_dot;
} sensorPacket;

sensorPacket angle_packet;

// struct per le variabili di stato
struct pendulumState {
  double theta;
  double theta_dot;
  double pos;
  double vel;
} state;

// ingresso, deve persistere anche fuori dal ciclo di loop
float u; 
// posizione da raggiungere del carrello
double cart_target = 0.0;
// angolo di offset interno
double angle_offset = 0.0;
// se vero, scrive su seriale lo stato e l'ingresso del sistema
char gather_data = 'N';
bool debug_msg = true;

double direct_speed_drive = 0.0;

unsigned long last_time_recv = micros();

// ESP-NOW on reacv callback.
void OnDataRecv(uint8_t * mac, uint8_t *incomingData, uint8_t len) {
  // copies the whole packet inside angle_packet
  memcpy(&angle_packet, incomingData, sizeof(angle_packet));
}

// Schema di controllo a State-Feedback: un solo livello che controlla sia pendolo che carrello.
double loopSF(double dt) {
  sf_integral.integrate(dt, cart_target - state.pos);
  return -(K.w1 * state.theta + K.w2 * state.theta_dot + K.w3 * state.pos + K.w4 * state.vel) - sf_integral.getIntegral();
}

/* Schema di controllo a due pid a cascata: il pid interno tiene il pendolo dritto,
il pid esterno porta il carrello nella posizione indicata da "target" */
double loopPID(double dt) {
  double r = pid_outer.control(dt, cart_target - state.pos);
  double acc = pid_inner.control(dt, state.theta);

  double u = r - acc;
  return -u; // restituisce l'ingresso
}


// legge una stringa dal serial e, se un match è trovato, esegue il rispettivo comando.
void processSerialCommands() {
  if (Serial.available() > 0) {
    String inputStr = Serial.readStringUntil('\n');
    if (debug_msg) Serial.println(inputStr);

    // estrae il comando e (se esiste) un argomento, separati da uno spazio.
    int firstSpace = inputStr.indexOf(' '); // Find first space
    String cmd = inputStr.substring(0, firstSpace);
    String arg = inputStr.substring(firstSpace + 1);

    if (cmd == "ping") {
      Serial.println("pong!");
    
    // modifica la posizione target che si desidera venga raggiunta dal carrello.
    } else if (cmd == "get-mac") {
      Serial.println(WiFi.macAddress());

    } else if (cmd == "set-wave-freq") {
      float freq = arg.toDouble();
      if (!debug_msg) return;
      Serial.println("NOT-IMPLEMENTED Setted square wave frequency on step pin");

    } else if (cmd == "set-target") {
      // ci si aspetta che la stringa args contenga il valore di "target" da impostare.
      cart_target = arg.toDouble();
      if (!debug_msg) return;
      Serial.print("New target set:\t");
      Serial.println(cart_target);

    // modifica il loop di controllo utilizzato per il controllo del pendolo
    } else if (cmd == "set-speed") {
      // ci si aspetta che la stringa args contenga il valore di "target" da impostare.
      direct_speed_drive = arg.toDouble();
      if (!debug_msg) return;
      Serial.print("New speed set:\t");
      Serial.println(direct_speed_drive);

    // modifica il loop di controllo utilizzato per il controllo del pendolo
    }else if (cmd == "set-mode") {
      if (arg == "PID") {
        currentMode = ControllerType::PID;

        Serial.println("Control mode switched to PID");
      } else if (arg == "SF") {
        currentMode = ControllerType::FULL_SF;
        sf_integral.reset();
        Serial.println("Control mode switched to STATE-FEEDBACK");
      } else if (arg == "SPEED") {
        currentMode = ControllerType::SPEED;
        currentState = RUNNING;
        cart.motor_enabled(true);
        Serial.println("Control mode switched to direct speed control.");
      }

    // se attivo, scrive lo stato del sistema su seriale a ogni iterazione con un timestamp associato.
    } else if (cmd == "gather-data") {
      if (arg == "ON") {
        gather_data = 'T';
        Serial.println("Printing system state data to serial.");
      } else if (arg == "OFF") {
        gather_data = 'F';
        Serial.println("No longer printing system state data to serial.");
      } else if (arg == "ONBIN") {
        gather_data = 'B';
      }
    
    } else if (cmd == "debug") {
      if (arg == "ON") {
        debug_msg = true;
        Serial.println("Debug enabled.");
      } else if (arg == "OFF") {
        debug_msg = false;
      }
    
    // permette di disabilitare o abilitare il loop di controllo
    }else if (cmd == "en") {
      if (arg == "T") {
        currentState = ControllerState::OFF;
        cart.motor_enabled(true);
        if (!debug_msg) return;
        Serial.println("Controller enabled.");
      } else if (arg == "F") {
        currentState = ControllerState::SKIP;
        cart.motor_enabled(false);
        if (!debug_msg) return;
        Serial.println("Controller disabled.");
      }
    
    // stop di sicurezza
    } else if (cmd == "stop") {
      cart.motor_enabled(false);
    
    // se il pendolo è fermo, effettua uno swing up
    } else if (cmd == "swing-up") {
      Serial.println("Swing up initiated.");

    } else if (cmd == "set-microstep") {
      int us = arg.toInt();
      if (us < 0) cart.autoSelectMicrostepEnabled(true);
      else {
        cart.autoSelectMicrostepEnabled(false);
        cart.setMicrostepLevel(us);
      }

    } else if (cmd == "set-pid1") {
      editPidValues(&pid_inner, arg);
      if (!debug_msg) return;
      Serial.print("Edited inner PID gains:\t");
      pid_inner.printGains();

    } else if (cmd == "get-pid1") {
      Serial.print("Inner PID gains:\t");
      pid_inner.printGains();
    
    } else if (cmd == "set-pid2") {
      editPidValues(&pid_outer, arg);
      if (!debug_msg) return;
      Serial.print("Edited outer PID gains:\t");
      pid_outer.printGains();

    } else if (cmd == "get-pid2") {
      Serial.print("Outer PID gains:\t");
      pid_outer.printGains();
    
    } else if (cmd == "set-K") {
      editVec4Values(&K, arg);
      if (!debug_msg) return;
      Serial.print("State-feedback K gains:\t");
      printVector(K);
    
    } else if (cmd == "get-K") {
      Serial.print("State-feedback K gains:\t");
      printVector(K);
    
    } else if (cmd == "offset") {
      float doffset = arg.toDouble();
      angle_offset += doffset;
      if (!debug_msg) return;
      Serial.print("Offset set to:\t");
      Serial.println(angle_offset);

    } else if (cmd == "get-integrals") {
      float int1 = pid_inner.getIntegral();
      float int2 = pid_outer.getIntegral();
      Serial.print("Integral components of pid 1/2 are: ");
      Serial.print(int1, 10);
      Serial.print('\t');
      Serial.println(int1, 10);
    
    } else if (cmd == "help") {
      const char* helpmsg = 
      "\nHere's a list of commands:\n"
      "\t- get-mac: Prints MAC address of board.\n"
      "\t- set-target <float target>: changes the cart target position for all controllers.\n"
      "\t- set-mode <PID/SF/SPEED>: changes controller between PID, SF (state feedback) or direct SPEED control (mainly used for testing). \n"
      "\t- set-speed <float speed>: changes speed at which to drive the cart when in SPEED control mode.\n"
      "\t- set-microstep <int value>: change microstep resolution (from 0 to 4). set to -1 for auto selection.\n"
      "\t- gather-data <ON/OFF/ONBIN>: enables or disables system state monitoring through serial. ONBIN option prints data in binary format (faster).\n"
      "\t- en <T/F>: enables/disables the current control loop and motor.\n"
      "\t- stop: forcefully disables motor (for safety).\n"
      "\t- set-pid1/set-pid2 <p> <i> <d>: Change pid gains for pid1 (inner) or pid2 (outer).\n"
      "\t- get-pid1/get-pid2: prints pid1 or pid2 gains.\n"
      "\t- set-K <k1> <k2> <k3> <k4>: sets state-feedback gain matrix K.\n"
      "\t- get-K: prints state-feedback gain matrix K values.\n"
      "\t- offset <float amount>: adds specified amount of radians to the angle reading (additive over multiple calls)."
      "\t- debug <ON/OFF>: prints debug/info/response messages to serial.";
      Serial.println(helpmsg);
    } else {
      Serial.print("Unknown command: ");
      Serial.println(inputStr);
    }

    
  }
}

void printStateBin(float u) {
  unsigned long timestamp = millis();
  const char* start = "S-";
  const char* end = "-S";
  Serial.write(start);
  Serial.write((byte*)&timestamp, 4);
  Serial.write((byte*)&u, sizeof(u));
  Serial.write((byte*)&state.theta, sizeof(state.theta));
  Serial.write((byte*)&state.theta_dot, sizeof(state.theta_dot));
  Serial.write((byte*)&state.pos, sizeof(state.pos));
  Serial.write((byte*)&state.vel, sizeof(state.vel));
  Serial.println(end);
}

// scrive su seriale una rappresentazione in formato csv dello stato corrente del sistema.
void printState(float u) {
  Serial.print(millis());
  Serial.print(",\t");
  Serial.print(u); // ingresso di comando
  Serial.print(",\t");
  Serial.print(state.theta);
  Serial.print(",\t");
  Serial.print(state.theta_dot);
  Serial.print(",\t");
  Serial.print(state.pos);
  Serial.print(",\t");
  Serial.println(state.vel);
}


void setup() {
  // ================================ SERIAL INITIALIZATION
  Serial.begin(115200);
  while(!Serial);
  delay(1000);
  Serial.println("\n\nSerial initialized.");

  // ================================ ESP-NOW INITIALIZATION
  // Set device as a Wi-Fi Station
  WiFi.mode(WIFI_STA);

  // Init ESP-NOW
  if (esp_now_init() != 0) {
    Serial.println("Error initializing ESP-NOW, startup-halted.");
    while (1) {delay(1000);}
  }

  esp_now_set_self_role(ESP_NOW_ROLE_SLAVE);
  esp_now_register_recv_cb(OnDataRecv);
  Serial.println("ESP-NOW initialized.");

  // ================================ CART CONFIGURATION
  cart.motor_enabled(false);
  cart.linkMicrostepController(&ms_controller);
  delay(200);

  cart.autoSelectMicrostepEnabled(true);
  Serial.println("End of setup. Enter 'help' on serial to get a list of all commands.");
  delay(100);
}

void loop()
{
  processSerialCommands();

  // garantisce frequenza di loop costante del codice sottostante
  if (clock_inner.tickUs(LOOP_PERIOD_US)) {

    const float dt = clock_inner.getdt();

    // lettura dello stato
    state.theta = angle_packet.theta + angle_offset; // gets latest packets
    state.theta_dot = angle_packet.theta_dot;
    state.vel = cart.getVelocity();
    state.pos = cart.getPosition();

    if (gather_data == 'T') printState(u);
    if (gather_data == 'B') printStateBin(u);

    // controller (approccio a state-machine)
    switch (currentState) {

      case ControllerState::SKIP:
        // in questo stato il controller non fa nulla e NON può autonomamente transizionare ad altri stati.
        // questo stato è raggiunto solo tramite comando dell'utente.
        break;

      // quanto è OFF
      case ControllerState::OFF:

        u = 0;
        pid_inner.clear();
        pid_outer.clear();
        cart.reset();
        sf_integral.reset();
        
        // attiva il controller se ritorna nell'area linearizzata
        if (abs(state.theta) < 0.4) {
          currentState = RUNNING;
          cart.motor_enabled(true);
          Serial.println("Entered linearization zone.");
        }
        break;

      // quando è RUNNING
      case ControllerState::RUNNING:

        // se esce dall'area linearizzata, disabilità il controller.
        if (abs(state.theta) > 0.4 && (currentMode != ControllerType::SPEED)) {
          cart.motor_enabled(false);
          currentState = OFF;
          Serial.println("Exited linearization zone.");
          Serial.println(state.theta);
          delay(1000);
          break;
        } else if (abs(state.pos) > 20000) {
          cart.motor_enabled(false);
          currentState = OFF;
          Serial.println("Cart went out of bounds.");
          delay(1000);
          break;
        }

        // depending on 
        switch (currentMode) {
        case ControllerType::PID:
          u = loopPID(dt);
          break;
        case ControllerType::FULL_SF:
          u = loopSF(dt);
          break;
        case ControllerType::SPEED:
          u = 0.0;
          break;
        }
        break;
        
    }
  }

  // aggiorna lo stepper fuori dal loop a 100Hz, per avere una risposta più fluida possibile.
  const float dt_real = clock_outer.getdt();
  u = constrain(u, -INPUT_RANGE, INPUT_RANGE);

  if (currentMode == ControllerType::SPEED) cart.driveSpeed(direct_speed_drive);
  else cart.driveAccel(dt_real, u);

  //Serial.println(dt_real, 10); // about 11-12 ms
}
