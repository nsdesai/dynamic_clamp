// A constant conductance with a reversal potential of -70 mV
float Shunting(float v) {
  float current = -gShunt * (v + 70);
  return current;
}


