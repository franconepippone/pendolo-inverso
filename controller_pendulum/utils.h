#pragma once
#include <Arduino.h>

#include "pid.h"

const float negPowersOf2[] = {
    1.0f,        // 2^0
    0.5f,        // 2^-1
    0.25f,       // 2^-2
    0.125f,      // 2^-3
    0.0625f,     // 2^-4
    0.03125f     // 2^-5
};

// look up the requested power of 2
float getNegPowerOf2(int n) {
    if (n >= 0 && n < sizeof(negPowersOf2) / sizeof(negPowersOf2[0])) {
        return negPowersOf2[n];
    } else {
        return pow(2, -n); // fallback for out-of-bound values
    }
}

struct Vec4 {
    union {
        struct { float x, y, z, w; }; // Named access
        struct { float w1, w2, w3, w4; }; // Alternative names
        float data[4]; // Array-like access
    };

    // Constructor
    Vec4(float x_ = 0, float y_ = 0, float z_ = 0, float w_ = 0)
        : x(x_), y(y_), z(z_), w(w_) {}

    // Operator[] for index-based access
    float& operator[](size_t index) {
        return *(&x + index);  // Treat memory as an array
    }

    const float& operator[](size_t index) const {
        return *(&x + index);
    }
};

/*Parses a string containing the three pid values written in decimal and in order, separated by spaces,
and assignes them to the passed pid*/
void editPidValues(PID* pid, String& strvalues) {
  int spaceIdx1 = strvalues.indexOf(' '); // Find first space
  int spaceIdx2 = strvalues.indexOf(' ', spaceIdx1 + 1); // Find second space

  float p = strvalues.substring(0, spaceIdx1).toDouble();
  float i = strvalues.substring(spaceIdx1, spaceIdx2).toDouble();
  float d = strvalues.substring(spaceIdx2 + 1).toDouble();

  pid->p = p;
  pid->i = i;
  pid->d = d;
}

void printVector(Vec4& vec) {
  Serial.print(vec.x);
  Serial.print('\t');
  Serial.print(vec.y);
  Serial.print('\t');
  Serial.print(vec.z);
  Serial.print('\t');
  Serial.println(vec.w);
}

void editVec4Values(Vec4* vec, String& strvalues) {
  int spaceIdx1 = strvalues.indexOf(' '); // Find first space
  int spaceIdx2 = strvalues.indexOf(' ', spaceIdx1 + 1); // Find second space
  int spaceIdx3 = strvalues.indexOf(' ', spaceIdx2 + 1); // Find third space

  vec->x = strvalues.substring(0, spaceIdx1).toDouble();
  vec->y = strvalues.substring(spaceIdx1, spaceIdx2).toDouble();
  vec->z = strvalues.substring(spaceIdx2, spaceIdx3).toDouble();
  vec->w = strvalues.substring(spaceIdx3 + 1).toDouble();
}

inline auto max(auto n1, auto n2) {
    return n1 > n2 ? n1 : n2; 
}


class numericalIntegrator {
public:
    double gain = 1.0;
    double integral = 0.0;

    numericalIntegrator(double gain) : gain(gain) {}

    void integrate(double dt, double value) {
        integral += value * dt * gain;
    }

    void reset() {integral = 0.0;}

    inline double getIntegral() {return integral;} 
};  

