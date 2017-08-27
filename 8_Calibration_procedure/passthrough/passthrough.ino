// Teensy sketch that reads an analog input and immediately sends it out an analog output.
// This can be used to calibrate the input part of the dynamic clamp system.
//
// Last modified 06/15/17.

// hardware connections
const int analogInPin = 0;        // ADC pin used to read membrane potential
const int analogOutPin = A21;     // DAC pin used to output current

// number of readings to average
const int nAverage = 5;

void setup() {
  Serial.begin(115200);
  analogWriteResolution(12);
  analogReadResolution(12);
  while (Serial.available()>0) {            // make sure serial buffer is clear  
    char foo = Serial.read();
  }
}

void loop() {
  int inputVal = 0;
  for (int x=0; x<nAverage; x++) {
    inputVal += analogRead(analogInPin);
  }
  int outputSignal = inputVal/nAverage;
  analogWrite(analogOutPin,outputSignal);
  delay(100);
}
