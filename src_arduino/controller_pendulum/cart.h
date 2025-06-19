#pragma once

#include <Arduino.h>
#include <math.h>
#include <AccelStepper.h>

#include "utils.h"
#include "microstep_controller.h"

#define MOTOR_ARM_L 9.5 //cm
#define DEFAULT_STEP_ANG_RAD 1.8 * DEG_TO_RAD
#define MAX_STEP_FREQ 500.0
#define MAX_VEL 150 // il sistema ottimizzerà il microstepping per tenersi sempre al di sotto di questa soglia

/*Rappresenta il carrello su cui è ancorato il pendolo. Astrae il controllo del motore passo passo in un unica funzione "driveAccel",
che permette di muovere il carrello con l'accelerazione (tangenziale) desiderata.
*/
class PendulumCart {
  AccelStepper motor;
  const int en_pin;
  double velocity = 0.0;
  float position = 0.0;

  MicrostepController* microstep_controller = nullptr;
  unsigned short int ms_amount = 0;
  bool auto_select_ms = false;
  double dist_to_steps; // fattore di conversione fra lo spostamento tangenziale della base del pendolo (in cm) e il numero di passi necessari
  double steps_to_dist; // inverso del precedente

  inline short int getMicrostepFromOmega(float w) {
    return max(0, floor(log(MAX_STEP_FREQ * DEFAULT_STEP_ANG_RAD / abs(w)) / log(2)));
  }

  inline  void autoSelectMS() {
    short int level = getMicrostepFromOmega(velocity / MOTOR_ARM_L);
    if (microstep_controller != nullptr) {
      setMicrostepLevel(level);
    }
  }

public:
  PendulumCart(const int en_pin, const int step_pin, const int dir_pin) : 
    en_pin(en_pin), 
    motor(AccelStepper(AccelStepper::DRIVER, step_pin, dir_pin)) 
  {
    setMicrostepLevel(0); // defaults to no microstep
    pinMode(en_pin, OUTPUT);
    motor.setMaxSpeed(20000);
    motor_enabled(false); // turns off motor
  }
  
  inline void autoSelectMicrostepEnabled(bool enabled) {
    auto_select_ms = enabled;
  }

  // sets microstepping level from 0 (no microstep) to 4 (1/16 microstep)
  void setMicrostepLevel(unsigned short int level) {
    level = constrain(level, 0, 4);
    if (level == ms_amount) return; // if it's already at that level, returns.
    ms_amount = level; //saves last set level
     
    // computes the angle moved per step : rad(1.8°) * 2^(-microstep) 
    double rad_per_step = DEFAULT_STEP_ANG_RAD * getNegPowerOf2(level);
    steps_to_dist = rad_per_step * MOTOR_ARM_L;
    dist_to_steps = 1.0 / steps_to_dist;

    // se è stato linkato un controller, aggiorna il microstepping sul driver.
    if (microstep_controller != nullptr) {
      microstep_controller->setMicrostep(level);
    }
  }

  void linkMicrostepController(MicrostepController* controller) {
    microstep_controller = controller;
  }

  // drives the cart with the wanted acceleration in cm/s^2
  void driveAccel(float dt, float acc) {
    velocity += acc * dt;
    position += velocity * dt;
    velocity = constrain(velocity, -MAX_VEL, MAX_VEL);
    if (auto_select_ms) autoSelectMS();
    motor.setSpeed(velocity * dist_to_steps);
    motor.runSpeed();
  }

  void driveSpeed(float speed) {
    velocity = speed;
    if (auto_select_ms) autoSelectMS();
    motor.setSpeed(velocity * dist_to_steps);
    Serial.print(velocity * dist_to_steps);
    Serial.print("\t");
    Serial.println(motor.runSpeed());
  }

  double getVelocity() {
    return velocity;
  }

  double getPosition() {
    return position;
  }

  // enable / disable the motor
  void motor_enabled(bool state) {
    digitalWrite(en_pin, !state);
  }

  void reset() {
    motor.setCurrentPosition(0);
    velocity = 0.0;
    position = 0.0;
  }
};