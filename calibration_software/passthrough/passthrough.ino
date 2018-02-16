// Teensy sketch that reads an analog input and immediately sends it out an analog output.
// This can be used to calibrate the input part of the dynamic clamp system.
//
// Last modified 02/16/18.

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
  float avg = 0;  // mean value of inputVal
  float m = 10;   // maximum number of averages
  float n = 0;    // current number of averages
  while(n < m){
    float inputVal = analogRead(analogInPin);
    delay(100);   // wait for new, digitized samples
    avg = (n/(n+1)) * avg + (1/(n+1)) * inputVal;
    n++;
  }
  analogWrite(analogOutPin,avg);
  delay(50);
  Serial.println(int(avg));
}
