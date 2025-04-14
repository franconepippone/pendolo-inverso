#pragma once

#include <Arduino.h>
#define MUs_TO_S 1.0E-6


/*classe di utilità per gestire con precisione le dinamiche temporali all'interno dei cicli
*/
class Clock {
  double last_time_s = 0.0;
  long unsigned int last_time_us = 0;
  
public:
  // returns the amount of seconds passed since last call.
  double getdt() {
    double time = micros() * MUs_TO_S;
    double dt = (time - last_time_s);
    last_time_s = time;
    return dt;
  }

  // returns true if it's time for a new iteration at the given rate.
  bool tickUs(long unsigned int microseconds) {
    auto now = micros();
    if (now < (last_time_us + microseconds)) return false;
    last_time_us = now;
    return true;
  } 

  bool tickMs(unsigned long milliseconds) {
    return tickUs(milliseconds * 1000);
  }
};