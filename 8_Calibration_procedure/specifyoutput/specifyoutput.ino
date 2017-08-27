// hardware connections
const int analogInPin = 0;        // ADC pin used to read membrane potential
const int analogOutPin = A21;     // DAC pin used to output current

void setup() {
  Serial.begin(115200);
  analogWriteResolution(12);
  analogReadResolution(12);
  while (Serial.available()>0) {            // make sure serial buffer is clear  
    char foo = Serial.read();
  }
}

void loop() {
  union {
    byte asByte[2];
    float asFloat;
  } data1;
  float dataTemp = 0.0f;
  if (Serial.available()>1) {
    for (int x=0; x<2; x++) data1.asByte[x] = Serial.read();
    dataTemp = data1.asFloat; 
    analogWrite(analogOutPin,(int)dataTemp);
  }
}
