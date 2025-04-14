#pragma once
#include <Arduino.h>

#define INT_MAX_WINDUP 1000

class PID {
public:
    float err_last = 0.0;
    float err_int = 0.0;

public:
    float p;
    float i;
    float d;

    PID(float p, float i, float d) {
        this->p = p;
        this->i = i;
        this->d = d;
    }

    float control(float dt, float err) {
	    float err_der = (err-err_last)/dt; // numerical differentiation
      err_last = err;
      err_int += err * dt * i;
      err_int = constrain(err_int, -INT_MAX_WINDUP, INT_MAX_WINDUP);
      return err * p + err_int + err_der * d;
    }

    void clear() {
        err_int = 0.0;
        err_last = 0.0;
    }

    // Print gains to deafult serial in a user-readable way.
    void printGains() {
      Serial.print(p);
      Serial.print('\t');
      Serial.print(i);
      Serial.print('\t');
      Serial.println(d);
    }
};