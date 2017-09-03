// Each EPSC is triggered by a LOW --> HIGH transition at epscTriggerPin.
// The two-stage kinetic scheme is similar to how NMDA currents are handled 
// in Walcott, Higgins, and Desai, J. Neurosci. (2011).

volatile float xEPSC = 0.0;                // a pure number, EPSC intermediate gating variable

// Increment xEPSC by 1 every time a trigger arrives at epscTriggerPin
void UpdateEpscTrain() {
  xEPSC += 1;
}

// Calculate the net EPSC current at every time step
float EPSC(float v) {
  const float tauX = 1.0;                       // msec, rise time
  const float tauS = 10.0;                      // msec, decay time
  const float alphaS = 1.0;                     // number/msec, saturation level
  static float s = 0.0;           
  xEPSC = xEPSC + dt * (-xEPSC/tauX);           
  s = s + dt * (-s/tauS + alphaS*xEPSC*(1-s));  // forward Euler method
  float current = -gEPSC * s * (v-0);           // reversal potential 0 mV
  return current;
}

