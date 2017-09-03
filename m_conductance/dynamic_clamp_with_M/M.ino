
// Declare the lookup table variables
float m_inf[1501] = {0.0};                                     // Pre-calculate the activation parameters for
float m_tau[1501] = {0.0};                                     // M currents: Vm from -100 mV to +50 mV in
                                                               // steps of 0.1 mV
// Generate the lookup tables
void GenerateMLUT() {
  float v;
  for (int x=0; x<1501; x++) {
    v = (float)x/10 - 100;                                     // x goes from 0 to 150, so v goes from -100 to +50
    m_inf[x] = 1/(1 + expf(-(v+35.0)/5.0)); 
    m_tau[x] = 1/(3.3*expf((v+35)/40) + expf(-(v+35)/20));
  }
}

// At every time step, calculate the HCN current in the Hodgkin-Huxley manner
float M(float v) {
  static float m_Var = 0.0;                                      // activation gate
  float v10 = v*10.0;
  int vIdx = (int)v10 + 100;
  vIdx = constrain(vIdx,0,1500);
  m_Var = m_Var + dt * ( -(m_Var-m_inf[vIdx])/m_tau[vIdx] );     // forward Euler method
  if (m_Var<0.0) m_Var=0.0;                                      // non-negative only
  float current = -gM * m_Var * (v + 80);                        // injected current (pA) 
  return current;
}


