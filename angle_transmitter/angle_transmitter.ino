#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <espnow.h>
#include <AS5600.h>
#include "clock.h"

#define UPDATE_FREQUENCY 210
#define LOOP_PERIOD 1.0 / UPDATE_FREQUENCY / MUs_TO_S
#define SENSOR_DIR_PIN 14

#define POT_OFFSET_SCALE .2 / 511.0
#define OFFSET_READ_DEADZONE .01  // pot reading must vary by at least this amount in order to make a change (prevents noise)

enum potReadState {LOCKED, READING};

potReadState currentPotState = LOCKED;

unsigned int potLockTimer = 0;
float startReadOffset = 0.0;

const double   AS5600_RAW_TO_RADIANS_double    = PI * 2.0 / 4096;

AS5600 AngleSensor;   //  use default Wire
Clock loopclock;
Clock loop_secondary;

double angle_offset = 0;
double angle_pot_offset = 0;

// THIS BOARD MAC IS 8c:aa:b5:0f:f9:e2
// receiver mac address
uint8_t receiverAddress[] = {0xC8, 0x2B, 0x96, 0x23, 0x14, 0x2B};


// Must match the receiver structure
typedef struct sensorPacket {
  double theta;
  double theta_dot;
} sensorPacket;

sensorPacket angle_state;

// Callback when data is sent
void OnDataSent(uint8_t *mac_addr, uint8_t sendStatus) {
  if (sendStatus != 0) {
    Serial.println("Delivery fail");
  }
}

// used for multisampling analog inputs to avarage noise
double multisampleAnalog(const unsigned int analogPin, const unsigned int samples) {
  unsigned long sum = 0;
  for (int i = 0; i < samples; i++) sum += analogRead(analogPin);
  return (double)sum / (double)samples;
}

double lerp(double from, double to, double amount) {
  return from + (to - from) * amount;
}

void setup() {
  // ============================== SERIAL INITIALIZATION
  Serial.begin(115200);
  while(!Serial);
  delay(1000);


  // ============================== ESP NOW INITIALIZATION
  // initialize wifi for ESP-NOW
  WiFi.mode(WIFI_STA);
  WiFi.begin();

  if (esp_now_init() != 0) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }

  // Once ESPNow is successfully Init, we will register for Send CB to
  // get the status of Transmitted packet
  esp_now_set_self_role(ESP_NOW_ROLE_CONTROLLER);
  esp_now_register_send_cb(OnDataSent);

  // Register peer
  esp_now_add_peer(receiverAddress, ESP_NOW_ROLE_SLAVE, 1, NULL, 0);

  // ============================== ANGLE SENSING INITIALIZATION
  Wire.begin(); // inizializza l'i2c
  AngleSensor.begin(SENSOR_DIR_PIN);
  AngleSensor.setDirection(AS5600_CLOCK_WISE);
  delay(200);

  // signaling led
  pinMode(LED_BUILTIN, OUTPUT);

  const int success = AngleSensor.isConnected();
  const auto address = AngleSensor.getAddress();
  if (success) {
    Serial.print("\n\nSensor is successfully connected at address: ");
    Serial.println(address, HEX);
  } else {
    Serial.println("\n\nSensor failed to connect, startup halted.");
    while (true) {delay(100); digitalWrite(LED_BUILTIN, !digitalRead(LED_BUILTIN));};
  }

  delay(200);

  angle_offset = AngleSensor.readAngle() * AS5600_RAW_TO_RADIANS_double - PI + 0.08; // il pendolo si trova a testa in giù
  Serial.print("Angle offset: \t");
  Serial.println(angle_offset);
  delay(200);

}

void loop()
{
    const double dt = loopclock.getdt();

    double new_theta = (AngleSensor.readAngle() * AS5600_RAW_TO_RADIANS_double - angle_offset + angle_pot_offset);
    new_theta = lerp(angle_state.theta, new_theta, 1);
    angle_state.theta_dot = lerp(angle_state.theta_dot, (new_theta - angle_state.theta) / dt, .2);
    angle_state.theta = new_theta;

    // Send message via ESP-NOW, if the time has come
    if (loopclock.tickUs(LOOP_PERIOD)) {
      esp_now_send(receiverAddress, (uint8_t *) &angle_state, sizeof(angle_state));
      Serial.print(angle_state.theta, 10);
      Serial.print("\t");
      Serial.print(angle_state.theta_dot, 10);
      Serial.print("\t");
      Serial.println(angle_pot_offset, 10);
    }
    
    // every 200ms update offset from pot
    if (loop_secondary.tickMs(200)) {
      const float pot = multisampleAnalog(A0, 150);
      angle_pot_offset = lerp(angle_pot_offset, (pot - 511) * POT_OFFSET_SCALE, .5);
    }

    delay(2); // 0.002 seconds
}

































