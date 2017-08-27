// Teensy sketch used in conjunction with the Processing calibration sketch.
// 
// Last modified 06/27/17.

// variables for current injections
const int nOutputs = 13;
float outputs[nOutputs];
float inputs[nOutputs];

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
  outputs[0] = 2400.0;                // initial choices to establish correct range
  outputs[1] = outputs[0]-100;
  analogWrite(analogOutPin,outputs[0]);
}


void loop() {
  if (Serial.available()>0){
    cmd = Serial.read();
    if (cmd==1) {                           // cmd=1, measure analog input
      Serial.println(analogRead(analogInPin));
    }
    if (cmd==2) {                           // cmd=2, inject analog output and measure analog input
      analogWrite(analogOutPin,outputs[0]);
      delay(settlingTime);
      inputs[0] = analogRead(analogInPin);
      analogWrite(analogOutPin,outputs[1]);
      delay(settlingTime);
      inputs[1] = analogRead(analogInPin);
      float slope = (inputs[1]-inputs[0])/(outputs[1]-outputs[0]);  // we use the initial two measurements to estimate
      float intercept = inputs[0] - slope*outputs[0];               // a range of outputs that will more-or-less cover
      float minOutput = round((1000 - intercept)/slope);            // the range of inputs the Teensy ADC can measure
      float maxOutput = round((3000 - intercept)/slope);
      float increment = (maxOutput - minOutput)/(nOutputs-3);
      for (int x=0; x<(nOutputs-2); x++) {
        outputs[x+2] = minOutput + round(increment*x);
        analogWrite(analogOutPin,outputs[x+2]);
        delay(settlingTime);
        inputs[x+2] = analogRead(analogInPin);
      }
      for (int y=0; y<nOutputs; y++) {
        Serial.print(outputs[y]);
        Serial.print(" , ");
        Serial.println(inputs[y]);
      }
    }
    analogWrite(analogOutPin,outputs[0]);
  }
}

