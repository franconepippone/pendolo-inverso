
class smartPotentiometer {
  const unsigned int analogPin;

  float deadzoneCenter = 0.0;
  float deadzoneWidth = 0.0;

public:
  smartPotentiometer(const unsigned int analogPin) : analogPin(analogPin) {}

  unsigned int read() {return analogRead(analogPin);}

  // used for multisampling analog inputs to avarage noise
  float read(const unsigned int samples) {
    unsigned long sum = 0;
    for (int i = 0; i < samples; i++) sum += analogRead(analogPin);
    return (float)sum / (float)samples;
  }

  float setDeadzoneCenter(float center) {deadzoneCenter = center;}
  float setDeadzoneWidth(float width) {deadzoneWidth = width;}

  float readWithDeadzone(unsigned int samples = 0) {
    float val = read(samples) - deadzoneCenter;
    return sign(val) * max(0, sign(val)*val - deadzoneWidth);
  }

}


void updatePotValue() {
    int currentValue = readPot();

    // Check if still within deadzone
    if (abs(currentValue - lastStableValue) <= DEADZONE_WIDTH) {
        // Still in deadzone, do nothing
        stableCounter = 0;
        stableCandidate = lastStableValue;
        return;
    }

    // Now we’re outside deadzone, check if currentValue is stable
    if (abs(currentValue - stableCandidate) <= STABLE_TOLERANCE) {
        stableCounter++;
        if (stableCounter >= STABLE_THRESHOLD) {
            // New stable value found
            lastStableValue = stableCandidate;
            stableCounter = 0;
            // You can now use `lastStableValue` to update your offset
        }
    } else {
        // New candidate
        stableCandidate = currentValue;
        stableCounter = 1;
    }
}