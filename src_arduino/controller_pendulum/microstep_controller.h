#pragma once
#include <Arduino.h>

/*Un generico controller di microstepping. Deve essere subclassato per implementare il microstepping su uno specifico driver.
*/
class MicrostepController {
public:
  virtual void setMicrostep(int value) = 0;
};

/*Implementa il microstepping sul driver a4988.
*/
class A4988microstepController : public MicrostepController {
  // pins
  const unsigned int MS1, MS2, MS3;

public:
  A4988microstepController(uint8_t MS1, uint8_t MS2, uint8_t MS3) : 
    MS1(MS1), MS2(MS2), MS3(MS3) {
      pinMode(MS1, OUTPUT);
      pinMode(MS2, OUTPUT);
      pinMode(MS3, OUTPUT);
    }
  
  void setMicrostep(int value) override {
    switch (constrain(value, 0, 4)) {
      case 0:
        digitalWrite(MS1, LOW);
        digitalWrite(MS2, LOW);
        digitalWrite(MS3, LOW);
        break;
      
      case 1:
        digitalWrite(MS1, HIGH);
        digitalWrite(MS2, LOW);
        digitalWrite(MS3, LOW);
        break;
      
      case 2:
        digitalWrite(MS1, LOW);
        digitalWrite(MS2, HIGH);
        digitalWrite(MS3, LOW);
        break;
      
      case 3:
        digitalWrite(MS1, HIGH);
        digitalWrite(MS2, HIGH);
        digitalWrite(MS3, LOW);
        break;
      
      case 4:
        digitalWrite(MS1, HIGH);
        digitalWrite(MS2, HIGH);
        digitalWrite(MS3, HIGH);
        break;
    }
  }
};