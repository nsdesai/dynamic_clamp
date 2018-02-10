// Teensy sketch used in conjunction with the Processing calibration sketch.
// 
// Last modified 02/09/18.

// variables for current injections
const int nOutputs = 13;
int outputs[nOutputs];
int inputs[nOutputs];

// hardware connections
const int analogInPin = 0;            // ADC pin used to read membrane potential
const int analogOutPin = A21;         // DAC pin used to output current

// global variables
int cmd;
float t0 = millis();
int settlingTime = 500;               // msec, time to wait for voltage to reach a steady state 
                                      // (i.e., for the model cell capacitors to charge/discharge)


void setup() {
  Serial.begin(115200);
  analogWriteResolution(12);
  analogReadResolution(12);
  while (Serial.available()>0) {      // make sure serial buffer is clear  
    char foo = Serial.read();
  }
  analogWrite(analogOutPin,2048);
  for (int z=0; z<nOutputs; z++) {    // DAC outputs between 300 and 3900 in increments of 300
    outputs[z] = 300*(z+1);
  }
}


void loop() {
  if (Serial.available()>0){
    cmd = Serial.read();
    if (cmd==1) {                           // cmd=1, measure analog input
      Serial.println(analogRead(analogInPin));
    }
    if (cmd==2) {                           // cmd=2, inject analog output and measure analog input
      for (int x=0; x<nOutputs; x++) {
        analogWrite(analogOutPin,outputs[x]);
        delay(settlingTime);
        inputs[x] = analogRead(analogInPin);
      }
      for (int y=0; y<nOutputs; y++) {
        Serial.print(outputs[y]);
        Serial.print(" , ");
        Serial.println(inputs[y]);
      }
    }
    analogWrite(analogOutPin,2048);
  }
}

