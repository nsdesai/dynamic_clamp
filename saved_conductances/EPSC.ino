// Train of EPSCs modeled as a difference of exponentials


// N is the total number of points in the train. epscConductances is the conductance train itself.
const int N = int(freq * duration / 1000);
float epscConductances[N];  


// When the sketch is uploaded to the board, this function is run to calculate the train of EPSCs.
void CreateEpscTrain() {
  memset(epscConductances,0,sizeof(epscConductances));
  int nStart = 0;
  int nInterval = int(epscInterval * freq / 1000.0); 
  float nRise = epscRise * freq / 1000.0;
  float nDecay = epscDecay * freq / 1000.0;
  for (int yy=0; yy<epscNum; yy++) {
    nStart = yy*nInterval;
    for (int zz=0; zz<N; zz++) {
      if (zz>=nStart) {
        epscConductances[zz] +=  gEPSC*expf(-(zz-nStart)/nDecay)-expf(-(zz-nStart)/nRise);
      }
    }
  }
}


// At every time step, this function is called to return the EPSC current given the membrane potential v.
float EPSC(float v, float t1) {
  const float epscRev = 0.0;
  int nt = int(t1 * freq / 1E6);
  float current = -epscConductances[nt] * (v - epscRev);   
  return current;
}

