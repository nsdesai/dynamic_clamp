// hardware connections
const int analogOutPin = A21;     // DAC pin used to output current

void setup() {
  Serial.begin(115200);
  analogWriteResolution(12);
  while (Serial.available()>0) {            // make sure serial buffer is clear  
    char foo = Serial.read();
  }
}

void loop() {
  int outputNumber = 0;
  if (Serial.available()>0) {
    outputNumber = Serial.parseInt();
    outputNumber = constrain(outputNumber,0,4095);
    analogWrite(analogOutPin,outputNumber);
    delay(50);
    Serial.println(outputNumber);
  }
}
