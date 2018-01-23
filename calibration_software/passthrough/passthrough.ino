// Teensy sketch that reads an analog input and immediately sends it out an analog output.
// This can be used to calibrate the input part of the dynamic clamp system.
//
// Last modified 01/23/18.

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
  int inputVal = analogRead(analogInPin);
  analogWrite(analogOutPin,inputVal);
  delay(50);
  Serial.println(inputVal);
  delay(50);
}
