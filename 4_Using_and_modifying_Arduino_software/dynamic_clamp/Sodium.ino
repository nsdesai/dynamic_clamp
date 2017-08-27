// A fast, transient Na+ conductance using the Hodgkin-Huxley formalism.
// For speed, the parameters alphaM, betaM, alphaH, and betaH are pre-calculated
// and put in lookup tables stored as global variables.

// Declare the lookup table variables
float alphaM[1501] = {0.0};                          // Pre-calculate activation and inactivation parameters 
float betaM[1501] = {0.0};                           // for sodium currents: Vm from -100 mV to +50 mV in 
float alphaH[1501] = {0.0};                          // steps of 0.1 mV
float betaH[1501] = {0.0};

// Generate the lookup tables
void GenerateSodiumLUT() {
  float v;
  for (int x=0; x<1501; x++) {
    v = (float)x/10 - 100.0;                        // We use membrane potentials between -100 mV and +50 mV
    if (x==600) {                                   // The if-else statement makes sure alphaM stays finite at v = -40 mV.
      alphaM[x] = 1.0;
    } else {
      alphaM[x] = 0.1 * (-(v+40.0)) / ( expf( -(v+40.0)/10 ) - 1 );
    }
    betaM[x] = 4.0 * expf(-(v+65)/18);
    alphaH[x] = 0.07 * expf(-(v+65)/20);
    betaH[x] = 1 / ( expf(-(v+35)/10 ) + 1); 
  }
}

// At every time step, calculate the sodium current in the Hodgkin-Huxley manner
float Sodium(float v) {
  static float mNaVar = 0.0;    // activation gate
  static float hNaVar = 1.0;    // inactivation gate
  float v10 = v*10.0;
  int vIdx = (int)v10 + 1000;
  vIdx = constrain(vIdx,0,1500);
  mNaVar = mNaVar + dt * ( alphaM[vIdx]*(1-mNaVar) - betaM[vIdx]*mNaVar );
  if (mNaVar < 0.0) mNaVar = 0.0;
  hNaVar = hNaVar + dt * ( alphaH[vIdx]*(1-hNaVar) - betaH[vIdx]*hNaVar );
  if (hNaVar < 0.0) hNaVar = 0.0;
  float current1 = -gNa * mNaVar * mNaVar * mNaVar * hNaVar * (v - 50);  // ENa = +50 mV
  return current1;
}

